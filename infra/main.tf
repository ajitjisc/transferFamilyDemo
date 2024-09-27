# First S3 Bucket
resource "aws_s3_bucket" "home_bucket" {
  bucket = "my-tf-test-bucket-${var.aws_profile}"
}


# Second S3 Bucket
resource "aws_s3_bucket" "home_bucket_2" {
  bucket = "my-tf-test-bucket-2-${var.aws_profile}"
}

# Second S3 Bucket
resource "aws_s3_bucket" "home_bucket_3" {
  bucket = "my-tf-test-bucket-3-${var.aws_profile}"
}