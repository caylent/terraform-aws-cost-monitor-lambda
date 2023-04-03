#!/bin/bash
set -e

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 081291135487.dkr.ecr.us-east-1.amazonaws.com
docker build -t cost_lambda .
docker tag cost_lambda:latest 081291135487.dkr.ecr.us-east-1.amazonaws.com/cost_lambda:latest
docker push 081291135487.dkr.ecr.us-east-1.amazonaws.com/cost_lambda:latest
aws lambda update-function-code --function-name  cost_alert --image-uri 081291135487.dkr.ecr.us-east-1.amazonaws.com/cost_lambda:latest
#TODO start the docker engine image and test it