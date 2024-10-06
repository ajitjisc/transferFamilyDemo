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
        Resource = "arn:aws:codestar-connections:eu-west-2:270741935732:connection/181b2a03-1066-46c4-88c8-063de14f4239"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::demo-prod-transfam-pipeline-artifacts-bucket/*"
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetProjects"
        ],
        Resource = [
          "arn:aws:codebuild:eu-west-2:270741935732:project/TerraformBuildProject",
          "arn:aws:codebuild:eu-west-2:270741935732:project/ServerlessBuildProject"
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
        Resource = "arn:aws:logs:eu-west-2:270741935732:log-group:/aws/codebuild/*"
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
        Resource = "arn:aws:dynamodb:eu-west-2:270741935732:table/dev-lock-table"
      },
      {
        Effect = "Allow",
        Action = [
          "cloudformation:*"
        ],
        Resource = "arn:aws:cloudformation:us-east-1:270741935732:stack/serverlessFrameworkDemo-dev/*"
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