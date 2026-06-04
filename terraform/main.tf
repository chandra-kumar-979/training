resource "aws_ecr_repository" "app" {
  name                 = "rag-chatbot-app"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "ecr_repository_url" {
  description = "The URI of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}