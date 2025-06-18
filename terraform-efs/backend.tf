terraform {
  backend "s3" {
    bucket       = "fusion-statefiles"
    key          = "efs.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true # Enable S3 native locking
  }
}