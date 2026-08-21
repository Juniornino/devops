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

# 4. Base PostgreSQL managée par Amazon RDS
module "rds" {
  source = "../../modules/rds"

  environment          = var.environment
  app_name             = var.app_name
  db_subnet_ids        = module.vpc.database_subnet_ids
  db_security_group_id = module.vpc.db_security_group_id
  db_password          = var.db_password
}

# 5. Appel du Module Compute (Load Balancer, Bastion, EC2 Privés)
module "compute" {
  source = "../../modules/ec2"

  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids        = module.vpc.private_subnet_ids
  alb_security_group_id     = module.vpc.alb_security_group_id
  bastion_security_group_id = module.vpc.bastion_security_group_id
  app_security_group_id     = module.vpc.app_security_group_id
  db_password_parameter_arn = module.rds.password_parameter_arn
  instance_type             = "t3.micro"
}

# 6. Identite et permissions de la pipeline GitHub Actions
module "github_actions" {
  source = "../../modules/github-actions"

  environment         = var.environment
  aws_region          = var.aws_region
  github_owner        = "Juniornino"
  github_repository   = "devops"
  github_branch       = "main"
  ecr_repository_arns = [module.ecr_backend.repository_arn, module.ecr_frontend.repository_arn]
  app_instance_ids    = module.compute.app_instance_ids
}
