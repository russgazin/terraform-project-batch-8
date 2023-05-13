terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "rustemtentech"
    key    = "batch-8-project-state-file"
  }
}