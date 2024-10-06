variable "github_webhook_secret" {
  description = "The secret token for GitHub webhook authentication"
  type        = string
  sensitive   = true
}
