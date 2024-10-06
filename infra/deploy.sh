#!/bin/bash

# Define environment (dev or prod) based on the input argument
ENV=$1

# Ensure the script runs in the correct directory
cd infra || exit 1

if [ "$ENV" == "prod" ]; then
  # Temporary changes for production deployment
  if [ -f backend.tf ]; then
    sed -i.bak -e 's/default = "transfer-family-dev"/default = "transfer-family-prod"/' \
               -e 's/bucket = "la-sftp-datahub-tfstate-transfer-family-demo"/bucket = "la-sftp-datahub-tfstate"/' \
               -e 's/dynamodb_table  = "terraform_locks"/dynamodb_table  = "dev-lock-table"/' backend.tf
  else
    echo "Error: backend.tf not found in the infra directory."
    exit 1
  fi

  # Apply Terraform commands for production
  echo "Deploying to production environment..."
  terraform init -reconfigure
  terraform plan
  terraform apply -auto-approve

  # Revert the backend.tf file to its original state
  mv backend.tf.bak backend.tf

else
  # Default to dev environment deployment
  echo "Deploying to development environment..."
  terraform init -reconfigure
  terraform plan
  terraform apply -auto-approve
fi
