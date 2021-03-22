project_name = "hello-world"
domain_name  = "staging.helloworld.com"
region       = "ca-central-1"

enable_enhanced_reporting_enabled = false
enable_cloudwatch_alarms          = true

sns_subscription_emails = ["v8oz21jn9@relay.firefox.com"]

autoscaling = {
  min_size        = 1
  max_size        = 4
  breach_duration = 5
}
