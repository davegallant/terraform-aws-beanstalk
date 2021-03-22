SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Get the current working directory
CWD := $(shell basename $$PWD)

DOCKER_FILE ?= Dockerfile
DOCKER_IMAGE ?= $(shell echo $(CWD) | tr A-Z a-z | tr -cd '[:alnum:]' )
DOCKER_HOME ?= /home/terraform

TF_BACKEND_CONFIG ?= backends/staging.tfvars
TF_VAR_FILE ?= $(WORKSPACE).tfvars
REGION ?= ca-central-1
WORKSPACE ?=

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

container-build:
> docker build -t $(DOCKER_IMAGE) -f $(DOCKER_FILE) .
.PHONY: container-build

## container-run: Enter into a container that has all the necessary dependencies
container-run: container-build
> docker run \
  -u "$$(id -u):$$(id -g)" \
  -v "$$PWD":/$(DOCKER_IMAGE) \
  -w /$(DOCKER_IMAGE) \
  -v "$$HOME/.aws":$(DOCKER_HOME)/.aws \
  -v "$$HOME/.ssh":$(DOCKER_HOME)/.ssh \
  -ti \
  $(DOCKER_IMAGE)
.PHONY: container-run

## terraform-workspace: Switch to a terraform workspace
terraform-workspace:
ifndef WORKSPACE
> @echo "ERROR: 'WORKSPACE' variable unset!" && exit 1
endif
> @if terraform workspace list | grep -E '^\*?[ ]*$(WORKSPACE)$$' ; then \
    echo -e "Workspace '$(WORKSPACE)' already exists. Switching."; \
    terraform workspace select $(WORKSPACE); \
  else \
    terraform workspace new $(WORKSPACE); \
  fi
.PHONY: terraform-workspace

## terraform-init: Initialize the terraform workspace and remote state
terraform-init:
> terraform init -backend-config $(TF_BACKEND_CONFIG)
> $(MAKE) terraform-workspace WORKSPACE=$(WORKSPACE)
> terraform workspace select $(WORKSPACE)
.PHONY: terraform-init

## terraform-plan: Check what resources have changed
terraform-plan:
> terraform plan -var-file $(TF_VAR_FILE) -lock
.PHONY: terraform-plan

## terraform-apply: Apply all changes
terraform-apply:
> terraform apply -var-file $(TF_VAR_FILE) -lock
.PHONY: terraform-apply

## terraform-destroy: Destroy all terraform resources
.PHONY: terraform-destroy
> terraform destroy -var-file $(TF_VAR_FILE)
terraform-destroy:

## deploy: Deploy the latest version of the beanstalk app
deploy:
> aws --region $(REGION) elasticbeanstalk update-environment --environment-name $$(terraform output -raw env_name) --version-label $$(terraform output -raw app_version)
.PHONY: deploy

## precommit: Run all pre-commit hooks
precommit:
> pre-commit run \
 --all-files \
 --show-diff-on-failure
.PHONY: precommit

## help: Print this help message
help:
> @echo
> @echo "Usage:"
> @echo
> @sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /' | sort
> @echo
.PHONY: help
