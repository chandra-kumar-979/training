This terraform folder was simplified to only create an Amazon ECR repository for the application.

What changed:
- main.tf now contains a single `aws_ecr_repository` resource named `rag-chatbot-app`.
- providers.tf now references `var.region` and has the S3 backend commented out (re-enable if you use remote state).
- variables.tf reduced to `region` and `environment`.

Notes:
- Existing module directories (vpc, s3, ec2, subnet) were left in place to avoid accidental data loss, but are no longer referenced by `main.tf`.
- To apply this minimal configuration:
  - Ensure AWS credentials are available in the environment (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY).
  - Run `terraform init` then `terraform apply -auto-approve` in this folder.

If you want me to remove the old modules entirely or migrate their resources into separate stacks, tell me and I will do so.

