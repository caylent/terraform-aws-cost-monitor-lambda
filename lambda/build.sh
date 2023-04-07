#!/bin/bash
set -e

ECR_URI="081291135487.dkr.ecr.us-east-1.amazonaws.com"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI
docker build -t cost_lambda .
docker tag cost_lambda:latest $ECR_URI/cost_lambda:latest
docker push $ECR_URI/cost_lambda:latest
aws lambda update-function-code --function-name  cost_alert --image-uri $ECR_URI/cost_lambda:latest