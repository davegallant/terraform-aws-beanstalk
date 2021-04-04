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

## help: Print this help message
help:
> @echo
> @echo "Usage:"
> @echo
> @sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /' | sort
> @echo
.PHONY: help
