#################################
# S3

# S3 Bucket creation
resource "aws_s3_bucket" "bucket" {
  bucket = "simonresume"
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadForGetBucketObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket.arn}/*",
      }
    ]
  })

  bucket = aws_s3_bucket.bucket.id
}

#################################
# CLOUDFRONT

locals {
  s3_origin_id = "myS3Origin"
}

# Create Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}

# IAM Policy Document for CloudFont OriginAccessIdentity to access S3 Bucket
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

# Attach the policy document to the bucket
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Create CloudFront distribution with S3 Bucket as origin
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  aliases = ["simonhaddadgervais.com"]

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
    default_ttl            = 60
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  # My ACM certificate to allow SSL
  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.certificate.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.1_2016"
    cloudfront_default_certificate = false
  }
}

#################################
# ROUTE 53

# Reference the hosted zone
data "aws_route53_zone" "hosted_zone" {
  name = "simonhaddadgervais.com"
}

# Create an A record that points to CloudFront distribution
resource "aws_route53_record" "my_record" {
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
  name            = "simonhaddadgervais.com"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

# Create a record for certificate validation
resource "aws_route53_record" "record_validate" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = "Z0513579U6CHH2XQNOAD"
}
#################################
# AWS CERTIFICATE MANAGER
# Create ACM certificate
resource "aws_acm_certificate" "certificate" {
  domain_name = "simonhaddadgervais.com"

  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# Validate Certificate
resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.record_validate : record.fqdn]
}

