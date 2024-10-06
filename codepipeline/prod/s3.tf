# S3 Bucket for CodePipeline Artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "demo-prod-transfam-pipeline-artifacts-bucket" 

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
