# Terraform AWS Elastic Beanstalk Hello World

<!-- BEGIN mktoc -->
- [Description](#description)
- [Limitations / Omissions](#limitations--omissions)
- [Requirements](#requirements)
- [Terraform Backend](#terraform-backend)
  - [S3 Bucket](#s3-bucket)
  - [DynamoDB Table](#dynamodb-table)
- [Scripts](#scripts)
  - [Setup](#setup)
  - [Deploy](#deploy)
  - [Destroy](#destroy)
- [Continuous Integration (CI)](#continuous-integration-ci)
- [Continuous Delivery (CD)](#continuous-delivery-cd)
- [Monitoring](#monitoring)
<!-- END mktoc -->

## Description

This is a sample repo the deploys a hello world application to [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/), with its resources managed by terraform.

This can be deployed entirely with [AWS Free Tier](https://aws.amazon.com/free/).

The following is deployed:

- Python (flask) web application
- Elastic Beanstalk Environment
- CloudWatch Alarm that will send notifications to a configurable list of emails via SNS
- Classic Load Balancer
- Self-signed ACM certificate

## Limitations / Omissions

- This lacks both unit tests and integration tests which are critical to have for a production deployment
- This uses a self-signed certificate (the private key does not appear in build logs, but it is stored in terraform state)
- Many resources are not encrypted and should be with a [CMK](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#master_keys) which would allow cross-account bunkering (i.e. S3, DynamoDB)
- There is not a permission boundary on the IAM roles
- The load balancer does not accept HTTP (this could be trivially updated to redirect HTTP to HTTPS)
- There is a lack of customization in the terraform variables (This could easily be remedied by adding additional variables in [variables.tf](./variables.tf))
- The Beanstalk URL is currently wide open (ideally this should be inaccessible from the public internet)

## Requirements

> :information_source: If you do not have the following dependencies, `make` and `docker` are enough to enter the container. Run `make container-run` to enter into an environment that has all necessary dependencies.

- AWS CLI
- Terraform >= 0.14
- Python >= 3.8

## Terraform Backend

To store the state of terraform in a safe, remote place, a backend is required. An [S3 backend](https://www.terraform.io/docs/language/settings/backends/s3.html) is fairly simple to setup.

### S3 Bucket

Create an S3 bucket to store the terraform state files:

```sh
export BUCKET=terraform-state-eb-hello-world # this needs to be globally unique
export REGION=ca-central-1

# Create the bucket
aws s3 mb s3://$BUCKET --region $REGION

# Enable Bucket Versioning to allow for state recovery in the case of accidental deletions and human error
aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled

# Update the backend tfvars with the newly created bucket name
sed -i "s/bucket.*= \".*\"/bucket         = \"$BUCKET\"/g" backends/*.tfvars
```

### DynamoDB Table

Create a DynamoDB Table that terraform will use for state locking:

```sh
export REGION=ca-central-1

aws dynamodb --region $REGION create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Scripts

Common [boilerplate scripts](https://github.com/github/scripts-to-rule-them-all#scripts-to-rule-them-all) are used to encourage a normalized script pattern across projects.

These variables can be used to override script defaults:

| VARIABLE          | DESCRIPTION                                         |
| ----------------- | --------------------------------------------------- |
| REGION            | AWS region to deploy into. Defaults to ca-central-1 |
| TF_BACKEND_CONFIG | Path to the backend variables file                  |
| TF_VAR_FILE       | Path to the terraform variables file                |
| TF_WORKSPACE      | Terraform workspace to use                          |

### Setup

To setup the workspace and backend, run:

```sh
TF_WORKSPACE=staging ./script/setup
```

### Deploy

```sh
# Use terraform to apply resources and
# the awscli to deploy the latest version of the app
REGION=ca-central-1 TF_VAR_FILE=staging.tfvars TF_WORKSPACE=staging ./script/deploy
```

### Destroy

To destroy all resources (and save money), run:

```sh
TF_WORKSPACE=staging TF_VAR_FILE=staging.tfvars ./script/destroy
```

## Continuous Integration (CI)

CI leverages GitHub Actions. The workflow is defined in [terraform.yml](./.github/workflows/terraform.yml).

There are branch protections on `main`.

All PRs require the `ci` GitHub Action steps to pass before merging.

These `ci` steps confirm:

- terraform code is formatted consistently
- terraform can be validated successfully
- terraform can be planned against staging successfully

## Continuous Delivery (CD)

CD also leverages the same GitHub Actions workflow as CI.

When a PR is merged into `main`, deployments to `staging` and `production` will kick off sequentially.

The `production` environment requires a reviewer to sign off before the deployment occurs.

## Monitoring

This web service can be monitored using the Elastic Beanstalk Monitoring tab, which by default includes average latency of requests, CPU utilization, and environment health codes.

There is a terraform variable `enable_enhanced_reporting_enabled` that enables [Enhanced health reporting and monitoring](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html). By default, enhanced reporting is disabled.
