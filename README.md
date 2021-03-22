# Terraform AWS Elastic Beanstalk Hello World

<!-- BEGIN mktoc -->

- [Description](#description)
- [Limitations / Omissions](#limitations--omissions)
- [Setup](#setup)
  - [Requirements](#requirements)
  - [Terraform Backend](#terraform-backend)
    - [S3 Bucket](#s3-bucket)
    - [DynamoDB Table](#dynamodb-table)
  - [Apply Resources](#apply-resources)
  - [Deploy](#deploy)
- [Destroy](#destroy)
- [CI/CD](#ci-cd)
<!-- END mktoc -->

## Description

This is a sample app the deploys a hello world application to [AWS Elastic Beanstalk](https://aws.amazon.com/elasticbeanstalk/), with its resources managed by terraform.

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

## Setup

### Requirements

> :information_source: If you do not have the following dependencies, `make` and `docker` are enough to enter the container. Run `make container-run` to enter into an environment that has all necessary dependencies.

- AWS CLI
- GNU Make >= 3.8
- Terraform >= 0.14
- Python >= 3.8

### Terraform Backend

To store the state of terraform in a safe, remote place, a backend is required. An [S3 backend](https://www.terraform.io/docs/language/settings/backends/s3.html) is fairly simple to setup.

#### S3 Bucket

Create an S3 bucket to store the terraform state files.

```sh
export BUCKET=terraform-state-eb-hello-world # this needs to be globally unique
export REGION=ca-central-1

# Create the bucket
aws s3 mb s3://$BUCKET --region $REGION

# Enable Bucket Versioning to allow for state recovery in the case of accidental deletions and human error
aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled
```

#### DynamoDB Table

Create a DynamoDB Table that terraform will use for state locking

```sh
export REGION=ca-central-1

aws dynamodb --region $REGION create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Apply Resources

These variables are used within the Makefile and can be overridden:

| VARIABLE          | DESCRIPTION                                         |
| ----------------- | --------------------------------------------------- |
| REGION            | AWS region to deploy into. Defaults to ca-central-1 |
| TF_BACKEND_CONFIG | Path to the backend variables file                  |
| TF_VAR_FILE       | Path to the terraform variables file                |
| WORKSPACE         | Terraform workspace to use                          |

To apply the resources, run:

```sh
make terraform-init WORKSPACE=staging

make terraform-apply WORKSPACE=staging
```

For additional targets, run `make help`.

### Deploy

```sh
# Use the awscli to deploy the latest version of the app
make deploy REGION=ca-central-1
```

## Destroy

To destroy all resources, run:

```sh
make terraform-destroy TF_VAR_FILE=staging.tfvars
```

## CI/CD

This repo is setup with branch protections on `main`.

All PRs require the `ci` GitHub Action steps to pass.

When a PR is merged into `main`, deployments to `staging` and `production` kick off sequentially.

The `production` environment requires a reviewer to sign off on the deployment.
