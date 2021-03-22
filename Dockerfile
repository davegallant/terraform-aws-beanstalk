FROM amazonlinux:2@sha256:0cdc09882f5bc2fe506a6f5ba84ab01b50787c12bcea6a1e4762ab6174450a37

ARG TERRAFORM_VERSION=0.14.8
ARG PYTHON_VERSION=python3.8

RUN amazon-linux-extras enable ${PYTHON_VERSION} && \
  yum install -y \
  awscli \
  git \
  make \
  python38-devel \
  shadow-utils \
  sudo \
  unzip \
  util-linux && \
  # Ensure python38 is symlinked
  cd /usr/bin && \
  ln -sf ${PYTHON_VERSION} python3 && \
  ln -sf ${PYTHON_VERSION}-config python3-config && \
  python3 -m pip install --no-cache --upgrade \
  pip==21.0.1 \
  pre-commit==2.11.1

RUN adduser terraform

# Install terraform
RUN curl -o /tmp/terraform.zip \
  https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  unzip /tmp/terraform.zip -d /usr/local/bin && \
  rm /tmp/terraform.zip

# Install tflint
RUN curl -o /tmp/tflint.zip -LO \
  https://github.com/terraform-linters/tflint/releases/download/v0.25.0/tflint_linux_amd64.zip && \
  unzip /tmp/tflint.zip -d /usr/local/bin && \
  rm /tmp/tflint.zip
