# IAM Role for CodePipeline with CodeStar permissions
resource "aws_iam_role" "codepipeline_role" {
  name = "CodePipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach policies to CodePipeline role
resource "aws_iam_policy" "codepipeline_policy" {
  name = "CodePipelinePolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:UseConnection"
        ],
        Resource = "arn:aws:codestar-connections:eu-west-2:492883160621:connection/c5ac251e-4e89-4e22-be0b-10e48f21a273" # Update this ARN with your actual connection ARN
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::demo-transfam-pipeline-artifacts-bucket/*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetProjects"
        ],
        Resource = [
          "arn:aws:codebuild:eu-west-2:492883160621:project/TerraformBuildProject",
          "arn:aws:codebuild:eu-west-2:492883160621:project/ServerlessBuildProject"
        ]
      }
    ]
  })
}


resource "aws_iam_policy_attachment" "codepipeline_policy_attach" {
  name       = "codepipeline-policy-attach"
  roles      = [aws_iam_role.codepipeline_role.name]
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}


# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# CodeBuild IAM policy to include S3, DynamoDB, and CloudFormation permissions
resource "aws_iam_policy" "codebuild_logs_policy" {
  name = "CodeBuildLogsPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:eu-west-2:492883160621:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:*"
        ],
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"
        ],
        Resource = "arn:aws:dynamodb:eu-west-2:492883160621:table/terraform_locks"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudformation:*"
        ],
        Resource = "arn:aws:cloudformation:us-east-1:492883160621:stack/serverlessFrameworkDemo-dev/*" # Update this ARN to match your CloudFormation stack
      },
      {
        Effect = "Allow",
        Action = [
          "cloudformation:ValidateTemplate"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:*" 
        ],
        Resource = "*" 
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach policies to CodeBuild role
resource "aws_iam_policy_attachment" "codebuild_policy_attach" {
  name       = "codebuild-policy-attach"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

# Attach the new CloudWatch Logs and S3 permissions policy to CodeBuildRole
resource "aws_iam_policy_attachment" "codebuild_logs_policy_attach" {
  name       = "codebuild-logs-and-s3-policy-attach"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = aws_iam_policy.codebuild_logs_policy.arn
}

# S3 Bucket for CodePipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "demo-transfam-pipeline-artifacts-bucket" 

  # Optionally, you can add server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "PipelineArtifacts"
    Environment = "Dev"
  }
}

# Separate resource for bucket versioning
resource "aws_s3_bucket_versioning" "pipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}


# CodePipeline setup
resource "aws_codepipeline" "transfer_family_pipeline" {
  name     = "TransferFamilyPipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  # Source stage using GitHub version 2 with CodeStar Connection
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
        ConnectionArn   = "arn:aws:codestar-connections:eu-west-2:492883160621:connection/c5ac251e-4e89-4e22-be0b-10e48f21a273"
        FullRepositoryId = "ajitjisc/transferFamilyDemo"
        BranchName      = "main"
      }

      # Define a namespace for the source stage variables
      namespace = "SourceVariables"
    }
  }

  # Terraform stage
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

  # Serverless stage
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


# CodeBuild Project for Terraform
resource "aws_codebuild_project" "terraform_project" {
  name         = "TerraformBuildProject"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"
    privileged_mode = true  # If needed for Docker builds

    # Remove explicit AWS_PROFILE environment variable
    environment_variable {
      name  = "ENV"
      value = "main"  # Set the environment variable to "main" or any other branch
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "infra/buildspec-terraform.yml"  # Adjust path if necessary
  }

  artifacts {
    type = "CODEPIPELINE"  # Required even if not using artifacts
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
    type = "CODEPIPELINE"  # Required even if not using artifacts
  }
}
