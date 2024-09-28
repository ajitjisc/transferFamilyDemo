# transferFamilyDemo
created for testing cicd pipeline
### Steps I Took to Build AWS CI/CD

1. **Create Connection**: I created a connection using CodeStar to connect with the GitHub repository. Currently, it’s public, but I need to find a way to make it a private repo while still allowing CodePipeline to use it as a source.

2. **Directory Structure**: I created a subdirectory called `CodePipeline` within the `transferFamilyDemo/` codebase, which contains `main.tf`. This file defines the full stack for CodePipeline and CodeBuild.

3. **Terraform Configuration**:
   - In the `infra/` directory, which contains Terraform configurations related to the `transferFamilyDemo` codebase, I created a new file called `buildspec-terraform.yml`. This file accomplishes three key tasks:
     - Installs dependencies.
     - Contains logic to determine whether `DEPLOY_ENV` is set to `dev` or `prod`.
     - Executes the `deploy.sh` shell script, which temporarily modifies `backend.tf` for production deployment. If it’s in development mode, it executes Terraform normally. The environment variable is passed from `SourceVariables.BranchName` in the Source stage.

4. **Serverless Framework Configuration**:
   - In the `serverlessFramework/` directory, I created a new file called `buildspec-serverless.yml`, which determines whether to deploy to the default development account or to `AWS_PROFILE="transfer-family-prod"`. The environment variable is also passed from `SourceVariables.BranchName` in the Source stage.

5. **Set Up AWS CodePipeline Webhook**:
   - I generated the `github_webhook_secret` using the command: 
     ```bash
     openssl rand -hex 32
     ```
   - I set up the resources in `codepipeline/main.tf`, including the variable `github_webhook_secret`, among others.
   - I exported the secret with:
     ```bash
     export TF_VAR_github_webhook_secret="c107e79d6929dab21b00f0684890712d6074446f017b83ac6076c95620af9a48"
     ```
   - I then ran `terraform apply`.
   - I obtained the Payload URL from the `TransferFamilyPipelineWebhook` we created in `codepipeline/main.tf` via the AWS CLI.
   - Finally, I went to the GitHub repository settings and set up the webhook with all the previous information.