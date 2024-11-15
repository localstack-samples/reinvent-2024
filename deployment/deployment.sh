export VPC_ID=$(awslocal ec2 create-vpc --cidr-block 10.0.0.0/16 | jq -r '.Vpc.VpcId')

export PRIVATE_SUBNET_ID1=$(awslocal ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  | jq -r '.Subnet.SubnetId')

export PRIVATE_SUBNET_ID2=$(awslocal ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  | jq -r '.Subnet.SubnetId')

export PUBLIC_SUBNET_ID1=$(awslocal ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1a \
  | jq -r '.Subnet.SubnetId')

export PUBLIC_SUBNET_ID2=$(awslocal ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1b \
  | jq -r '.Subnet.SubnetId')

export INTERNET_GW_ID=$(awslocal ec2 create-internet-gateway | jq -r '.InternetGateway.InternetGatewayId')

awslocal ec2 attach-internet-gateway \
  --internet-gateway-id $INTERNET_GW_ID \
  --vpc-id $VPC_ID

export PUBLIC_RT_ID=$(awslocal ec2 create-route-table \
  --vpc-id $VPC_ID \
  | jq -r '.RouteTable.RouteTableId')

awslocal ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_ID1

awslocal ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_ID2

awslocal ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $INTERNET_GW_ID

# Create NAT Gateway in the public subnet

export ALLOCATION_ID=$(awslocal ec2 allocate-address --query 'AllocationId' --output text)

export NAT_GW_ID=$(awslocal ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID1 \
  --allocation-id $ALLOCATION_ID \
  --query 'NatGateway.NatGatewayId' \
  --output text)

awslocal ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID

export PRIVATE_RT_ID=$(awslocal ec2 create-route-table \
  --vpc-id $VPC_ID \
  | jq -r '.RouteTable.RouteTableId')

awslocal ec2 associate-route-table \
  --route-table-id $PRIVATE_RT_ID \
  --subnet-id $PRIVATE_SUBNET_ID1

awslocal ec2 associate-route-table \
  --route-table-id $PRIVATE_RT_ID \
  --subnet-id $PRIVATE_SUBNET_ID2

awslocal ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $NAT_GW_ID

  export SG_ID1=$(awslocal ec2 create-security-group \
  --group-name ApplicationLoadBalancerSG \
  --description "Security Group of the Load Balancer" \
  --vpc-id $VPC_ID \
  | jq -r '.GroupId')

awslocal ec2 authorize-security-group-ingress \
  --group-id $SG_ID1 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

  export SG_ID2=$(awslocal ec2 create-security-group \
  --group-name ContainerFromLoadBalancerSG \
  --description "Inbound traffic from the First Load Balancer" \
  --vpc-id $VPC_ID \
  | jq -r '.GroupId')

awslocal ec2 authorize-security-group-ingress \
  --group-id $SG_ID2 \
  --protocol tcp \
  --port 0-65535 \
  --source-group $SG_ID1

  export LB_ARN=$(awslocal elbv2 create-load-balancer \
  --name ecs-load-balancer \
  --subnets $PUBLIC_SUBNET_ID1 $PUBLIC_SUBNET_ID2 \
  --security-groups $SG_ID1 \
  --scheme internet-facing \
  --type network \
  --type application \
  | jq -r '.LoadBalancers[0].LoadBalancerArn')


export LB_NAME=$(awslocal elbv2 describe-load-balancers \
  --load-balancer-arns $LB_ARN \
  | jq -r '.LoadBalancers[0].DNSName')

  export TG_ARN=$(awslocal elbv2 create-target-group \
  --name ecs-targets \
  --protocol HTTP \
  --port 8080 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-protocol HTTP \
  --region us-east-1 \
  --health-check-path /health \
  | jq -r '.TargetGroups[0].TargetGroupArn')

  awslocal elbv2 create-listener \
    --load-balancer-arn $LB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN

awslocal ecs create-cluster --cluster-name LocalStackMysteryCluster

awslocal ecr create-repository --repository-name mystery-service

docker build --no-cache -t mystery-service -f ../fargate-go/Dockerfile ../fargate-go/

docker tag mystery-service:latest 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/mystery-service:latest

docker push 000000000000.dkr.ecr.us-east-1.localhost.localstack.cloud:4566/mystery-service:latest


awslocal iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document file://ecs-task-role-policy.json

export ECS_TASK_POLICY_ARN=$(awslocal iam create-policy \
  --policy-name ecsTaskPolicy \
  --policy-document file://ecs-task-policy.json | jq -r '.Policy.Arn')

awslocal iam attach-role-policy \
  --role-name ecsTaskRole \
  --policy-arn $ECS_TASK_POLICY_ARN

awslocal iam update-assume-role-policy \
  --role-name ecsTaskRole \
  --policy-document file://ecs-cloudwatch-policy.json

# awslocal iam update-assume-role-policy \
#   --role-name ecsTaskRole \
#   --policy-document file://public-ecr-policy.json

awslocal iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://ecs-role-policy.json

export ECS_TASK_EXEC_POLICY_ARN=$(awslocal iam create-policy \
  --policy-name ecsTaskExecutionPolicy \
  --policy-document file://ecs-task-exec-policy.json | jq -r '.Policy.Arn')

awslocal iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn $ECS_TASK_EXEC_POLICY_ARN

awslocal iam update-assume-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-document file://ecs-cloudwatch-policy.json

# awslocal iam update-assume-role-policy \
#   --role-name ecsTaskExecutionRole \
#   --policy-document file://public-ecr-policy.json

awslocal logs create-log-group --log-group-name mystery-service-logs

awslocal ecs register-task-definition \
  --family mystery-service-task \
  --cli-input-json file://task_definition_awslocal.json


awslocal ecs create-service \
  --cluster LocalStackMysteryCluster \
  --service-name LocalStackMysteryService \
  --task-definition mystery-service-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNET_ID1, $PRIVATE_SUBNET_ID2],securityGroups=[$SG_ID2],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=mystery-service-container,containerPort=8080"


export API_ID=$(awslocal apigatewayv2 create-api \
  --name "LocalStackDocsAPI" \
  --protocol-type HTTP \
  --region us-east-1 \
  --query 'ApiId' \
  --output text)



export INTEGRATION_ID_EMPL=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/employee" \
  --integration-method POST \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /employee" \
  --target "integrations/$INTEGRATION_ID_EMPL"


awslocal apigatewayv2 create-stage \
  --api-id "$API_ID" \
  --stage-name prod \
  --auto-deploy
