resource "aws_s3_bucket" "test-bucket-ck" {
  bucket = var.bucket_name
  tags = {
    region      = var.region
    Environment = var.environment
  }
}

output "bucket_id" {
  value = aws_s3_bucket.test-bucket-ck.id
}

output "tags" {
  value = aws_s3_bucket.test-bucket-ck.tags
}
