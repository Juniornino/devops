resource "aws_db_subnet_group" "postgres" {
  name       = "${var.app_name}-${var.environment}-db"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "db-subnet-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.app_name}-${var.environment}-postgres"
  engine                  = "postgres"
  engine_version          = "16.9"
  instance_class          = var.instance_class
  allocated_storage       = 20
  max_allocated_storage   = 30
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = 5432
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  vpc_security_group_ids  = [var.db_security_group_id]
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 1
  apply_immediately       = true
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name        = "rds-postgres-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Copie chiffrée du mot de passe pour que les serveurs EC2 puissent le lire
# au démarrage sans l'écrire dans Docker Compose.
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.app_name}/${var.environment}/database/password"
  description = "Mot de passe PostgreSQL RDS pour ${var.app_name} (${var.environment})"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name        = "db-password-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
