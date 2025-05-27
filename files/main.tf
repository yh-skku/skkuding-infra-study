terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "skkuding-bucket-test"
    key    = "terraform/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}

data "aws_s3_bucket" "skkuding_bucket" {
  bucket = "skkuding-bucket-test"
}

resource "aws_s3_object" "html_file" {
  bucket = aws_s3_bucket.skkuding_bucket.bucket
  key    = "index.html"
  source = "./index.html"
  content_type = "text/html"
  etag= filemd5("./index.html")
}

resource "aws_s3_object" "css_file" {
  bucket       = aws_s3_bucket.skkuding_bucket.bucket
  key          = "style.css"
  source       = "./style.css"
  content_type = "text/css"
  etag         = filemd5("./style.css")
}


resource "aws_s3_object" "js_file" {
  bucket       = aws_s3_bucket.skkuding_bucket.bucket
  key          = "script.js"
  source       = "./script.js"
  content_type = "application/javascript"
  etag         = filemd5("./script.js")
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.skkuding_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "public_read_policy" {
  statement {
    sid     = "PublicReadGetObject"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.skkuding_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.skkuding_bucket.id
  policy = data.aws_iam_policy_document.public_read_policy.json
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.skkuding_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

data "aws_lb" "existing_alb" {
  name = "LB"
}

locals {
  s3_origin_id = "S3Origin"
  alb_origin_id = "ALBOrigin"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = local.s3_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = data.aws_lb.existing_alb.dns_name
    origin_id   = local.alb_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*" 
    target_origin_id       = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront for S3 and ALB"
  default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "skkuding-cloudfront"
  }
}
