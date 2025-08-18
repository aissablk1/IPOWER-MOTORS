# Configuration OIDC GitHub pour IPOWER MOTORS
# ===========================================

# Provider OIDC GitHub
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Identity Provider OIDC GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = ["sts.amazonaws.com"]
  
  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint
  ]
  
  tags = {
    Name = "GitHub-OIDC-Provider"
    Project = var.project_name
  }
}

# Rôle IAM pour GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "IPOWER-MOTORS-GitHub-Actions-Role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:ipower-motors/*"
          }
        }
      }
    ]
  })
  
  tags = {
    Name = "IPOWER-MOTORS-GitHub-Actions-Role"
    Project = var.project_name
  }
}

# Politique pour GitHub Actions
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "IPOWER-MOTORS-GitHub-Actions-Policy"
  role = aws_iam_role.github_actions.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Accès S3 pour déploiement frontend
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.ipower_frontend.arn,
          "${aws_s3_bucket.ipower_frontend.arn}/*"
        ]
      },
      # Accès CloudFront pour invalidation
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.ipower_frontend.arn
      },
      # Accès EC2 pour déploiement backend
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      # Accès SSM pour déploiement sécurisé
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      },
      # Accès IAM pour AssumeRole
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.ipower_ec2_role.arn
      },
      # Accès CloudWatch pour logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      # Accès SNS pour notifications
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.ipower_alerts.arn
      }
    ]
  })
}

# Politique pour déploiement EC2
resource "aws_iam_role_policy" "github_actions_ec2_policy" {
  name = "IPOWER-MOTORS-GitHub-Actions-EC2-Policy"
  role = aws_iam_role.github_actions.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Project": var.project_name
          }
        }
      }
    ]
  })
}

# Outputs pour GitHub Actions
output "github_actions_role_arn" {
  description = "ARN du rôle IAM pour GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN du provider OIDC GitHub"
  value       = aws_iam_openid_connect_provider.github.arn
}
