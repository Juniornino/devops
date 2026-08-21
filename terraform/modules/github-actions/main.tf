data "aws_caller_identity" "current" {}

# AWS fait confiance aux jetons temporaires emis par GitHub Actions.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Seule la branche main de ce depot GitHub peut prendre ce role.
resource "aws_iam_role" "github_actions" {
  name = "github-actions-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository}@${var.github_repository_id}:ref:refs/heads/${var.github_branch}"
        }
      }
    }]
  })

  tags = {
    Name        = "github-actions-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-deployment-${var.environment}"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "ECRPushImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = var.ecr_repository_arns
      },
      {
        Sid      = "DescribeApplicationInstances"
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      },
      {
        Sid    = "DeployWithSSM"
        Effect = "Allow"
        Action = "ssm:SendCommand"
        Resource = concat(
          ["arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"],
          [for instance_id in var.app_instance_ids : "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${instance_id}"]
        )
      },
      {
        Sid    = "ReadSSMCommandResult"
        Effect = "Allow"
        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      }
    ]
  })
}
