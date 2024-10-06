# CodeBuild Project for Terraform
resource "aws_codebuild_project" "terraform_project" {
  name         = "TerraformBuildProject"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "ENV"
      value = "main"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "infra/buildspec-terraform.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}

# CodeBuild Project for Serverless Framework
resource "aws_codebuild_project" "serverless_project" {
  name         = "ServerlessBuildProject"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "serverlessFramework/buildspec-serverless.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}
