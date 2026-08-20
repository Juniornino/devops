# 1. Appel du Module VPC d'Entreprise
module "vpc" {
  source = "../../modules/vpc"

  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24"]
  availability_zones    = ["eu-west-3a", "eu-west-3b"]
  enable_nat_gateway    = true
}

# 2. Appel du Module ECR (Registre Docker Backend)
module "ecr_backend" {
  source = "../../modules/ecr"

  repository_name = "${var.app_name}-backend"
  environment     = var.environment
}

# 3. Appel du Module ECR (Registre Docker Frontend)
module "ecr_frontend" {
  source = "../../modules/ecr"

  repository_name = "${var.app_name}-frontend"
  environment     = var.environment
}

# 4. Appel du Module Compute (Load Balancer, Bastion, EC2 Privés)
module "compute" {
  source = "../../modules/ec2"

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  alb_security_group_id      = module.vpc.alb_security_group_id
  bastion_security_group_id  = module.vpc.bastion_security_group_id
  app_security_group_id      = module.vpc.app_security_group_id
  instance_type              = "t3.micro"
}
