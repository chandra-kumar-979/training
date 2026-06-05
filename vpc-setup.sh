export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""

echo "=========================================="
echo "  Checking all VPCs in us-east-1"
echo "=========================================="

for VPC_ID in $(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text); do

  VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
    --query 'Vpcs[0].Tags[?Key==`Name`].Value' --output text)
  VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
    --query 'Vpcs[0].CidrBlock' --output text)
  IS_DEFAULT=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
    --query 'Vpcs[0].IsDefault' --output text)

  # Count resources
  EC2_COUNT=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[*].Instances[*].InstanceId' --output text | wc -w)

  EKS_COUNT=$(aws eks list-clusters --query 'clusters' --output text 2>/dev/null | wc -w)

  RDS_COUNT=$(aws rds describe-db-instances \
    --query "DBInstances[?DBSubnetGroup.VpcId=='$VPC_ID'].DBInstanceIdentifier" \
    --output text 2>/dev/null | wc -w)

  LB_COUNT=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerName" \
    --output text 2>/dev/null | wc -w)

  NAT_COUNT=$(aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query 'NatGateways[*].NatGatewayId' --output text | wc -w)

  ENI_COUNT=$(aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text | wc -w)

  SUBNET_COUNT=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].SubnetId' --output text | wc -w)

  echo ""
  echo "=========================================="
  echo "  VPC: $VPC_ID"
  echo "  Name: ${VPC_NAME:-<no name>}"
  echo "  CIDR: $VPC_CIDR"
  echo "  Default: $IS_DEFAULT"
  echo "------------------------------------------"
  echo "  EC2 Instances:    $EC2_COUNT"
  echo "  Load Balancers:   $LB_COUNT"
  echo "  RDS Databases:    $RDS_COUNT"
  echo "  NAT Gateways:     $NAT_COUNT"
  echo "  Network Interfaces: $ENI_COUNT"
  echo "  Subnets:          $SUBNET_COUNT"

  TOTAL=$((EC2_COUNT + LB_COUNT + RDS_COUNT))
  if [ "$IS_DEFAULT" == "True" ]; then
    echo "  Status: ⚠️  DEFAULT VPC (keep this)"
  elif [ "$TOTAL" -eq 0 ] && [ "$ENI_COUNT" -le "$SUBNET_COUNT" ]; then
    echo "  Status: ✅ LIKELY UNUSED - SAFE TO DELETE"
  else
    echo "  Status: 🔴 IN USE - DO NOT DELETE"
  fi
  echo "=========================================="

done