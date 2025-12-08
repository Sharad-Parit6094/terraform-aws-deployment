aws_region      = "us-east-1"
aws_profile     = "default"               # change if you use named profile
aws_account_id  = "123456789012"          # REPLACE with your account id
domain_name     = "yourdomain.com"        # REPLACE with your domain or DDNS
certificate_arn = ""                      # REPLACE with ACM certificate ARN (required for HTTPS)
microservice_image_uri = ""               # Optional initially; set after pushing to ECR
ssh_key_name    = ""                      # Optional: name of key pair in your AWS account
