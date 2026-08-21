# 1. Recherche dynamique de la dernière AMI Ubuntu 22.04 LTS officielle sur AWS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Owner ID officiel Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Rôle IAM commun aux instances EC2.
# Il autorise la lecture des images Docker dans ECR et l'administration via SSM.
resource "aws_iam_role" "ec2" {
  name = "role-ec2-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Autorise uniquement la lecture du mot de passe RDS prévu pour cette application.
resource "aws_iam_role_policy" "read_db_password" {
  name = "read-db-password-${var.environment}"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "ssm:GetParameter"
      Resource = var.db_password_parameter_arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "profile-ec2-${var.environment}"
  role = aws_iam_role.ec2.name
}

# 2. Clé SSH (Optionnelle - créée uniquement si fournie)
resource "aws_key_pair" "deployer" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "key-${var.environment}"
  public_key = var.ssh_public_key
}

# 3. Application Load Balancer (ALB) d'Entreprise
resource "aws_lb" "main" {
  name               = "alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "alb-${var.environment}"
    Environment = var.environment
  }
}

# 4. Target Group pour l'application E-commerce / NestJS / Nginx Proxy
resource "aws_lb_target_group" "app_tg" {
  name        = "tg-app-${var.environment}"
  port        = 8085
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "8085"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "tg-app-${var.environment}"
    Environment = var.environment
  }
}

# 5. Listener HTTP de l'ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 6. Bastion Host (Serveur SSH d'administration dans le sous-réseau public)
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [var.bastion_security_group_id]
  key_name                    = var.ssh_public_key != "" ? aws_key_pair.deployer[0].key_name : null
  associate_public_ip_address = true
  iam_instance_profile       = aws_iam_instance_profile.ec2.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y htop curl git net-tools
              EOF

  tags = {
    Name        = "ec2-bastion-${var.environment}"
    Environment = var.environment
    Role        = "Bastion-JumpHost"
  }
}

# 7. Instance EC2 Applicative dans le Sous-réseau Privé (Docker & NestJS)
resource "aws_instance" "app_server" {
  count                       = length(var.private_subnet_ids)
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_ids[count.index]
  vpc_security_group_ids      = [var.app_security_group_id]
  key_name                    = var.ssh_public_key != "" ? aws_key_pair.deployer[0].key_name : null
  associate_public_ip_address = false
  iam_instance_profile       = aws_iam_instance_profile.ec2.name

  # Script User Data d'initialisation automatique (Installation Docker & Docker Compose)
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y ca-certificates curl gnupg lsb-release git awscli
              
              # Installation de Docker
              sudo mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update -y
              sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
              
              # Démarrage & activation de Docker
              sudo systemctl enable docker
              sudo systemctl start docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name        = "ec2-app-server-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Role        = "Application-Server"
  }
}

# 8. Rattachement des instances EC2 applicatives au Target Group de l'ALB
resource "aws_lb_target_group_attachment" "app_attachment" {
  count            = length(aws_instance.app_server)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 8085
}
