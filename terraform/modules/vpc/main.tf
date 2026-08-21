# 1. Création du VPC principal Enterprise
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# 2. Internet Gateway (Passerelle Internet pour les sous-réseaux publics)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "igw-${var.environment}"
    Environment = var.environment
  }
}

# 3. Elastic IP & NAT Gateway (Accès Internet sécurisé pour les serveurs privés)
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "eip-nat-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "nat-gateway-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.gw]
}

# 4. Sous-réseaux publics (Exposés sur Internet - Load Balancers, Bastion)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "subnet-public-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Tier        = "Public"
  }
}

# 5. Sous-réseaux privés Applicatifs (EC2, Microservices, Docker, NestJS)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "subnet-private-app-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Tier        = "Private-App"
  }
}

# 6. Sous-réseaux privés Bases de Données (PostgreSQL, RDS - Isolés)
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "subnet-private-db-${count.index + 1}-${var.environment}"
    Environment = var.environment
    Tier        = "Private-Database"
  }
}

# 7. Tables de routage
## A. Table de routage publique (vers Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "rt-public-${var.environment}"
    Environment = var.environment
  }
}

## B. Table de routage privée (vers NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[0].id
    }
  }

  tags = {
    Name        = "rt-private-${var.environment}"
    Environment = var.environment
  }
}

## C. Table de routage Base de données (Totalement isolée)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "rt-database-${var.environment}"
    Environment = var.environment
  }
}

# 8. Associations des tables de routage
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = length(aws_subnet.database)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# 9. Security Groups d'Entreprise

## A. Security Group du Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-${var.environment}"
  description = "Autorise le trafic public entrant vers le Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP depuis Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS depuis Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Port Nginx Proxy 8085"
    from_port   = 8085
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-alb-${var.environment}"
    Environment = var.environment
  }
}

## B. Security Group du Bastion (Serveur SSH d'administration)
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-${var.environment}"
  description = "Autorise l acces SSH securise depuis l exterieur"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH depuis Internet ou IP Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-bastion-${var.environment}"
    Environment = var.environment
  }
}

## C. Security Group Applicatif (Serveurs EC2 Privés / Docker / NestJS)
resource "aws_security_group" "app_sg" {
  name        = "app-${var.environment}"
  description = "Autorise le trafic venant de ALB et du Bastion"
  vpc_id      = aws_vpc.main.id

  # Ingress depuis le Load Balancer
  ingress {
    description     = "Trafic applicatif depuis le Load Balancer"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Ingress SSH depuis le Bastion uniquement
  ingress {
    description     = "SSH uniquement depuis le Bastion Host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-app-${var.environment}"
    Environment = var.environment
  }
}

## D. Security Group Base de Données (PostgreSQL / RDS)
resource "aws_security_group" "db_sg" {
  name        = "database-${var.environment}"
  description = "Autorise uniquement l application et le Bastion a contacter PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL depuis les serveurs applicatifs"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  ingress {
    description     = "PostgreSQL administration depuis le Bastion"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sg-database-${var.environment}"
    Environment = var.environment
  }
}

  # Egress: Trafic Sortant illimité
