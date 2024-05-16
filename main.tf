resource "aws_s3_bucket" "b" {
  bucket = local.name
}

# Find a certificate that is issued
data "aws_acm_certificate" "issued" {
  domain = "*.malavear.com"
}

#resource "aws_s3_bucket_acl" "b_acl" {
#  bucket = aws_s3_bucket.b.id
#  acl    = "private"
#}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    #origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

#  logging_config {
#    include_cookies = false
#    bucket          = "mylogs.s3.amazonaws.com"
#    prefix          = "myprefix"
#  }

  aliases = ["resume.malavear.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.issued.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.b.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_cloudfront" {
  bucket = aws_s3_bucket.b.id
  policy = data.aws_iam_policy_document.allow_access_cloudfront.json
}

data "aws_iam_policy_document" "allow_access_cloudfront" {
  statement {
    principals {
      type = "*"
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.b.arn}/*",
    ]
  }
}