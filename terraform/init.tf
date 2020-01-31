variable "team" {}
variable "project" {}

variable "namespace" {}

variable "lambda_s3_bucket" {}
variable "lambda_s3_key" {}

terraform {
  backend "s3" {
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = "${data.aws_caller_identity.current.account_id}"
  name = "${var.team}-${var.project}"
}
