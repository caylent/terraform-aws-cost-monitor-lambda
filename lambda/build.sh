#!/bin/bash
set -e

ECR_URI="123456789012.dkr.ecr.us-east-1.amazonaws.com" # replace with a real URI
echo "loging in to ECR"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

echo "Building Image"
docker build -t cost_lambda .

echo "Tagging Image"
docker tag cost_lambda:latest $ECR_URI/cost_lambda:latest

echo "Pushing Image"
docker push $ECR_URI/cost_lambda:latest
echo "Image pushed to $ECR_URI"

if [ "$1" != "BOOTSTRAP" ]
then
aws lambda update-function-code --function-name  cost_alert --image-uri $ECR_URI/cost_lambda:latest
else
echo "This is the first time the image is deployed, skiping lambda update"
fi