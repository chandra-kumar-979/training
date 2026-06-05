#!/bin/bash
set -euo pipefail

AWS_REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="rag-api-tf-state-${ACCOUNT_ID}"
LOCK_TABLE="rag-api-tf-locks"

echo "=========================================="
echo "  Setting up Terraform Backend"
echo "=========================================="
echo "  Account:  ${ACCOUNT_ID}"
echo "  Bucket:   ${STATE_BUCKET}"
echo "  Table:    ${LOCK_TABLE}"
echo "=========================================="

# Create S3 bucket
echo ""
echo "Creating S3 bucket..."
if [ "$AWS_REGION" == "us-east-1" ]; then
  aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}"
else
  aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}"
fi

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "${STATE_BUCKET}" \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "${STATE_BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket "${STATE_BUCKET}" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table
echo ""
echo "Creating DynamoDB table..."
aws dynamodb create-table \
  --table-name "${LOCK_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}" 2>/dev/null || echo "Table may already exist"

echo ""
echo "=========================================="
echo "  ✅ Backend Setup Complete!"
echo "=========================================="
echo ""
echo "  Add these GitHub Secrets:"
echo ""
echo "    TF_STATE_BUCKET = ${STATE_BUCKET}"
echo "    TF_LOCK_TABLE   = ${LOCK_TABLE}"
echo ""
echo "=========================================="