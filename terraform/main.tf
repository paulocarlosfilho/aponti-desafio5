terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://s3.localhost.localstack.cloud:4566"
    ec2 = "http://localhost.localstack.cloud:4566"
  }
}

# ============================================================
# UPLOAD AUTOMÁTICO DOS ARQUIVOS PARA O S3
# ============================================================

variable "frontends" {
  type    = map(string)
  default = {
    "app-desafio-5-s3" = "../src"
  }
}

locals {
  frontend_files = merge([
    for bucket, folder in var.frontends : {
      for file in fileset("${path.module}/${folder}", "**") :
      "${bucket}/${file}" => {
        bucket = bucket
        source = "${path.module}/${folder}/${file}"
        key    = file
      }

      if !startswith(file, ".git/")
      && !startswith(file, ".vscode/")
      && !startswith(file, ".terraform/")
    }
  ]...)
}

resource "aws_s3_object" "frontend_files" {
  for_each = local.frontend_files

  bucket = aws_s3_bucket.desafio5.id
  key    = each.value.key
  source = each.value.source

  content_type = lookup(
    {
      ".html" = "text/html"
      ".css"  = "text/css"
      ".js"   = "application/javascript"
      ".json" = "application/json"
      ".png"  = "image/png"
      ".jpg"  = "image/jpeg"
      ".jpeg" = "image/jpeg"
      ".svg"  = "image/svg+xml"
      ".ico"  = "image/x-icon"
      ".gif"  = "image/gif"
      ".webp" = "image/webp"
    },
    lower(regex("\\.[^.]+$", each.value.key)),
    "application/octet-stream"
  )
  

  etag = filemd5(each.value.source)
}

resource "aws_s3_bucket" "desafio5" {
  bucket = var.bucket_name
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type

  tags = {
    Name = "Desafio5-AppServer"
  }
}