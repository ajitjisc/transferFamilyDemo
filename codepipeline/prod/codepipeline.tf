# CodePipeline setup for Prod
resource "aws_codepipeline" "transfer_family_pipeline_prod" {
  name     = "TransferFamilyPipelineProd"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn   = "arn:aws:codestar-connections:eu-west-2:270741935732:connection/181b2a03-1066-46c4-88c8-063de14f4239"
        FullRepositoryId = "ajitjisc/transferFamilyDemo"
        BranchName      = "main"
        DetectChanges    = "true"
      }

      namespace = "SourceVariables"
    }
  }

  # Terraform stage and Serverless stage
  stage {
    name = "Terraform"
    action {
      name             = "TerraformBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.terraform_project.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ENV"
            value = "#{SourceVariables.BranchName}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "DeployServerless"
    action {
      name             = "ServerlessDeploy"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.serverless_project.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ENV"
            value = "#{SourceVariables.BranchName}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}

# CodePipeline webhook for Prod
resource "aws_codepipeline_webhook" "codepipeline_webhook_prod" {
  name            = "TransferFamilyPipelineProdWebhook"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.transfer_family_pipeline_prod.name

  authentication = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = var.github_webhook_secret
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/main"  # For Prod
  }

  tags = {
    Environment = "Prod"
  }
}
