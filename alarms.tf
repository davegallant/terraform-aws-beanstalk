resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_actions             = [aws_sns_topic.alert_sns_topic.arn]
  alarm_description         = "This metric monitors ec2 cpu utilization"
  alarm_name                = "${terraform.workspace}-${var.project_name}-cpu"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  count                     = var.enable_cloudwatch_alarms ? 1 : 0
  evaluation_periods        = "2"
  insufficient_data_actions = []
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "1" # Set very low to trigger an alarm

  dimensions = {
    AutoScalingGroupName = element(aws_elastic_beanstalk_environment.this.autoscaling_groups, 0)
  }

}

resource "aws_sns_topic" "alert_sns_topic" {
  name            = "${terraform.workspace}-${var.project_name}"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "exponential"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

data "template_file" "aws_cf_sns_stack" {
  template = file("${path.module}/templates/cf_aws_sns_email_stack.tpl.json")
  vars = {
    sns_topic_arn         = aws_sns_topic.alert_sns_topic.arn
    sns_subscription_list = join(",", var.sns_subscription_emails)
  }
}

resource "aws_cloudformation_stack" "tf_sns_topic_subscription" {
  name          = "${terraform.workspace}-snsStack"
  template_body = data.template_file.aws_cf_sns_stack.rendered
}
