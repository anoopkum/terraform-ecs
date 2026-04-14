output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.app.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.app.name
}

output "github_actions_access_key" {
  description = "Access key for GitHub Actions"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_key" {
  description = "Secret key for GitHub Actions"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}
