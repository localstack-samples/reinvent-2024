#### ReInvent 2024 take-home challenge

General description: the user injects a cloud pod using the launch pad, navigates to an S3 hosted site (to be added) which will contain instructions on solving the mistery. Each endpoint in the Go app will provide different clues to solve the mystery.

Creating the stack: In the `deployment` folder run the `deployment.sh` script. This contains all the necessary AWS CLI commands to create the services.

Calling the endpoint: `curl http://<your-api-gw-id>.execute-api.localhost.localstack.cloud:4566/prod/employee` -> should return `Employee endpoint`

Architecture description: User -> Api Gateway -> Load Balancer -> LB Listener -> Target Group -> Security group -> VPC -> private subnet -> Fargate Cluster -> Service -> Running tasks

There might be some services that are no longer used in there, mainly because I made some changes - needs cleanup. Pls ignore.

Reproducing the cloud pod issue: Once the services are up, run `localstack state export mystery-pod-test`. Restart LocalStack & run `localstack state import mystery-pod`. The application will no longer respond when the endpoint is called. It seems the Fargate container is not spinning up.
