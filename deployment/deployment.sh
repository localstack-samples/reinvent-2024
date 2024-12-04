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

export ALLOCATION_ID1=$(awslocal ec2 allocate-address --query 'AllocationId' --output text)

export ALLOCATION_ID2=$(awslocal ec2 allocate-address --query 'AllocationId' --output text)


export NAT_GW_ID=$(awslocal ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID1 \
  --allocation-id $ALLOCATION_ID1 \
  --query 'NatGateway.NatGatewayId' \
  --output text)

export NAT_GW_ID=$(awslocal ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_ID2 \
  --allocation-id $ALLOCATION_ID2 \
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
  --group-name LoadBalancerSG \
  --description "Security Group of the Load Balancer" \
  --vpc-id $VPC_ID \
  | jq -r '.GroupId')

awslocal ec2 authorize-security-group-ingress \
  --group-id $SG_ID1 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

  awslocal apigatewayv2 create-vpc-link \
  --name my-vpc-link \
  --subnet-ids $PRIVATE_SUBNET_ID1 $PRIVATE_SUBNET_ID2 \
  --security-group-ids $SG_ID1

  export SG_ID2=$(awslocal ec2 create-security-group \
  --group-name ContainerSG \
  --description "Inbound traffic from the First Security Group" \
  --vpc-id $VPC_ID \
  | jq -r '.GroupId')

awslocal ec2 authorize-security-group-ingress \
  --group-id $SG_ID2 \
  --protocol tcp \
  --port 0-65535 \
  --source-group $SG_ID1

  export LB_ARN=$(awslocal elbv2 create-load-balancer \
  --name ecs-load-balancer \
  --subnets $PRIVATE_SUBNET_ID1 $PRIVATE_SUBNET_ID2 \
  --security-groups $SG_ID1 \
  --scheme internal \
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

# awslocal ecs update-service \
#     --cluster LocalStackMysteryCluster \
#     --service LocalStackMysteryService \
#     --task-definition mystery-service:2


export VPC_LINK_ID=$(awslocal apigatewayv2 create-vpc-link \
  --name my-vpc-link \
  --subnet-ids $PRIVATE_SUBNET_ID1 $PRIVATE_SUBNET_ID2 \
  --security-group-ids $SG_ID1 | jq -r '.VpcLinkId')


export API_ID=$(awslocal apigatewayv2 create-api \
  --name "LocalStackMysteryAPI" \
  --protocol-type HTTP \
  --region us-east-1 \
  --query 'ApiId' \
  --output text)

echo "REACT_APP_API_GATEWAY_ID=$API_ID" > ../frontend/.env

export INTEGRATION_ID_GINGER=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/suspects/gingerbread" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

export INTEGRATION_ID_ELF=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/suspects/elf" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

export INTEGRATION_ID_SNOWMAN=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/suspects/snowman" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

export INTEGRATION_ID_REINDEER=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/suspects/reindeer" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

export INTEGRATION_ID_CLUE1=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/hints/clue1" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

export INTEGRATION_ID_CLUE2=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/hints/clue2" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

export INTEGRATION_ID_WEATHER=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/weather" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /suspects/gingerbread" \
  --target "integrations/$INTEGRATION_ID_GINGER"

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /suspects/elf" \
  --target "integrations/$INTEGRATION_ID_ELF"

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /suspects/snowman" \
  --target "integrations/$INTEGRATION_ID_SNOWMAN"

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /suspects/reindeer" \
  --target "integrations/$INTEGRATION_ID_REINDEER"

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /hints/clue1" \
  --target "integrations/$INTEGRATION_ID_CLUE1"

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /hints/clue2" \
  --target "integrations/$INTEGRATION_ID_CLUE2"

awslocal apigatewayv2 create-route \
  --api-id "$API_ID" \
  --route-key "GET /weather" \
  --target "integrations/$INTEGRATION_ID_WEATHER"

cd ../frontend

npm run build

awslocal s3api create-bucket --bucket frontend --region us-east-1

awslocal s3 website s3://frontend/ --index-document index.html

awslocal s3api put-bucket-policy --bucket frontend --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::frontend/*"
    }
  ]
}'

awslocal s3api put-public-access-block --bucket frontend --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false


awslocal s3 sync ./build s3://frontend/ 

awslocal s3api put-bucket-cors --bucket frontend --cors-configuration '{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedMethods": ["GET", "POST", "PUT", "HEAD"],
            "AllowedHeaders": ["*"],
            "ExposeHeaders": ["ETag"],
            "MaxAgeSeconds": 3000
        }
    ]
}'

awslocal iam create-role \
  --role-name lambda_role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

awslocal iam attach-role-policy \
  --role-name lambda_role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

cd ../deployment  

awslocal lambda create-function \
  --function-name certificate-lambda \
  --runtime python3.9 \
  --role arn:aws:iam::000000000000:role/lambda_role \
  --handler handler.handler \
  --zip-file fileb://certificate-lambda.zip \
  --timeout 15

  # awslocal lambda update-function-code \
  # --function-name certificate-lambda \
  # --zip-file fileb://certificate-lambda.zip


export INTEGRATION_ID_LAMBDA=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type AWS_PROXY \
  --integration-uri arn:aws:lambda:us-east-1:000000000000:function:certificate-lambda \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text
  )

awslocal apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "POST /lambda" \
  --target "integrations/$INTEGRATION_ID_LAMBDA"

export INTEGRATION_ID_LAMBDA_OPTIONS=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type AWS_PROXY \
  --integration-uri arn:aws:lambda:us-east-1:000000000000:function:certificate-lambda \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text
  )

awslocal apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "OPTIONS /lambda" \
  --target "integrations/$INTEGRATION_ID_LAMBDA_OPTIONS"

export INTEGRATION_ID_ANSWER=$(awslocal apigatewayv2 create-integration \
  --api-id $API_ID \
  --integration-type HTTP_PROXY \
  --integration-uri "http://$LB_NAME:4566/answer" \
  --integration-method POST \
  --connection-type VPC_LINK \
  --connection-id $VPC_LINK_ID \
  --payload-format-version 1.0 \
  --query 'IntegrationId' \
  --output text)


awslocal apigatewayv2 create-route \
  --api-id $API_ID \
  --route-key "GET /answer" \
  --target "integrations/$INTEGRATION_ID_ANSWER"


awslocal apigatewayv2 create-stage \
  --api-id "$API_ID" \
  --stage-name prod \
  --auto-deploy

# awslocal apigatewayv2 create-deployment \
#     --api-id $API_ID \
#     --description "Deployment of all the integrations" \
#     --region us-east-1

awslocal apigatewayv2 update-api \
    --api-id $API_ID \
    --cors-configuration '{
        "AllowOrigins": ["https://frontend.s3-website.localhost.localstack.cloud:4566"],
        "AllowMethods": ["GET", "POST", "OPTIONS"],
        "AllowHeaders": ["*"]
    }' \
    --region us-east-1

awslocal apigatewayv2 update-api \
  --api-id $API_ID \
  --cors-configuration AllowOrigins="*",AllowMethods="GET,POST,OPTIONS",AllowHeaders="Content-Type,Authorization",AllowCredentials=false

  awslocal apigatewayv2 create-deployment \
    --api-id $API_ID \
    --description "Deployment of all the integrations" \
    --region us-east-1