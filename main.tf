locals {
  application_name = "${terraform.workspace}-${var.project_name}"
}

# Create a zip of the application/deployment
data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/${var.application.src_dir}"
  output_path = "${path.module}/dist/${var.application.src_dir}.zip"
}

resource "aws_s3_bucket" "dist_bucket" {
  bucket = "${terraform.workspace}-elb-dist"
  acl    = "private"
}

resource "aws_s3_bucket_object" "dist_item" {
  key    = "${terraform.workspace}/dist-${uuid()}"
  bucket = aws_s3_bucket.dist_bucket.id
  source = data.archive_file.this.output_path
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = local.application_name
  description = "A hello world webserver"
}

resource "aws_elastic_beanstalk_application_version" "this" {
  name        = "${local.application_name}-${uuid()}"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.dist_bucket.id
  description = "A hello world webserver"
  key         = aws_s3_bucket_object.dist_item.id
}

resource "aws_elastic_beanstalk_environment" "this" {
  application         = aws_elastic_beanstalk_application.app.name
  description         = "An environment for a hello world webserver"
  name                = local.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.2.0 running Python 3.8"
  tier                = "WebServer"

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = var.instance_type
    resource  = ""
  }

  # Auto Scaling
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2.name
    resource  = ""
  }

  setting {
    name      = "MaxSize"
    namespace = "aws:autoscaling:asg"
    value     = var.autoscaling.max_size
  }

  setting {
    name      = "MinSize"
    namespace = "aws:autoscaling:asg"
    value     = var.autoscaling.min_size
  }

  setting {
    name      = "BreachDuration"
    namespace = "aws:autoscaling:trigger"
    value     = var.autoscaling.breach_duration
  }

  # Load Balancer
  setting {
    namespace = "aws:elb:listener"
    name      = "ListenerEnabled"
    value     = false # Disable HTTP
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }
  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = var.application.port
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = aws_acm_certificate.this.arn
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerEnabled"
    value     = true
  }
}
