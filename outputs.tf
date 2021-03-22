output "env_url" {
  value = "https://${aws_elastic_beanstalk_environment.this.endpoint_url}"
}

output "app_version" {
  value = aws_elastic_beanstalk_application_version.this.name
}
