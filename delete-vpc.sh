export AWS_DEFAULT_REGION=us-east-1
export AWS_PAGER=""

# ============================================================
# CHANGE THIS to the VPC you want to delete
# ============================================================
DELETE_VPC="vpc-09c7f1b2fda7a26a6"

echo "=========================================="
echo "  Deleting VPC: ${DELETE_VPC}"
echo "=========================================="

# 1. Delete NAT Gateways
echo ">>> Deleting NAT Gateways..."
for NAT in $(aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$DELETE_VPC" "Name=state,Values=available" \
  --query 'NatGateways[*].NatGatewayId' --output text); do
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT
  echo "  Deleted NAT: $NAT"
done
echo "  Waiting 30s for NAT cleanup..."
sleep 30

# 2. Release Elastic IPs (from deleted NATs)
echo ">>> Releasing unused Elastic IPs..."
for EIP in $(aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].AllocationId' --output text); do
  aws ec2 release-address --allocation-id $EIP 2>/dev/null || true
  echo "  Released EIP: $EIP"
done

# 3. Delete Load Balancers
echo ">>> Deleting Load Balancers..."
for LB_ARN in $(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?VpcId=='$DELETE_VPC'].LoadBalancerArn" --output text); do
  aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
  echo "  Deleted LB: $LB_ARN"
done

# 4. Delete ENIs (Network Interfaces)
echo ">>> Deleting Network Interfaces..."
for ENI in $(aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$DELETE_VPC" \
  --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text); do

  # Detach first if attached
  ATTACH_ID=$(aws ec2 describe-network-interfaces \
    --network-interface-ids $ENI \
    --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text)

  if [ "$ATTACH_ID" != "None" ] && [ -n "$ATTACH_ID" ]; then
    aws ec2 detach-network-interface --attachment-id $ATTACH_ID --force 2>/dev/null || true
    sleep 5
  fi

  aws ec2 delete-network-interface --network-interface-id $ENI 2>/dev/null || true
  echo "  Deleted ENI: $ENI"
done

# 5. Detach and Delete Internet Gateway
echo ">>> Deleting Internet Gateway..."
for IGW in $(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$DELETE_VPC" \
  --query 'InternetGateways[*].InternetGatewayId' --output text); do
  aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $DELETE_VPC
  aws ec2 delete-internet-gateway --internet-gateway-id $IGW
  echo "  Deleted IGW: $IGW"
done

# 6. Delete Subnets
echo ">>> Deleting Subnets..."
for SUBNET in $(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$DELETE_VPC" \
  --query 'Subnets[*].SubnetId' --output text); do
  aws ec2 delete-subnet --subnet-id $SUBNET
  echo "  Deleted Subnet: $SUBNET"
done

# 7. Delete Route Tables (non-main)
echo ">>> Deleting Route Tables..."
for RT in $(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$DELETE_VPC" \
  --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
  aws ec2 delete-route-table --route-table-id $RT
  echo "  Deleted RT: $RT"
done

# 8. Delete Security Groups (non-default)
echo ">>> Deleting Security Groups..."
for SG in $(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$DELETE_VPC" \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
  aws ec2 delete-security-group --group-id $SG
  echo "  Deleted SG: $SG"
done

# 9. Delete VPC Endpoints
echo ">>> Deleting VPC Endpoints..."
for EP in $(aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$DELETE_VPC" \
  --query 'VpcEndpoints[*].VpcEndpointId' --output text); do
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $EP
  echo "  Deleted Endpoint: $EP"
done

# 10. Finally Delete the VPC
echo ">>> Deleting VPC..."
aws ec2 delete-vpc --vpc-id $DELETE_VPC
echo ""
echo "=========================================="
echo "  ✅ VPC ${DELETE_VPC} DELETED!"
echo "=========================================="