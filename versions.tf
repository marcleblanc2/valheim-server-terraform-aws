terraform {

    required_version = "~> 0.14"

    backend "s3" {
        bucket  = local.terraform_backend_s3_bucket
        key     = local.terraform_backend_s3_key
        region  = local.region
        encrypt = true
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 3.0"
        }
    }

}

provider "aws" {

    region = local.region

}
