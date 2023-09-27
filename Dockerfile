# Using official ubuntu image as a parent image
FROM ubuntu:22.04 AS builder-image
# FROM python:3.11-slim-bookworm


# avoid stuck build due to user prompt
ARG DEBIAN_FRONTEND=noninteractive \
    MODULAR_HOME=/home/apprunner/.modular \
    AUTH_KEY=DEFAULT_KEY

ENV VIRTUAL_ENV=/home/apprunner/venv \
    MODULAR_HOME=${MODULAR_HOME} \
    AUTH_KEY=${AUTH_KEY} \
    PATH="${PATH}:${MODULAR_HOME}/pkg/packages.modular.com_mojo/bin" 
    
RUN useradd -ms /bin/bash apprunner

# Getting the updates for Ubuntu and installing python into our environment
RUN apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive \
    && apt install --no-install-recommends -y \
        python3.10 \
        python3-pip \
        python3.10-venv \
        python3.10-dev \
        python3-pip \
        python3-wheel \
        build-essential \
        curl \
        wget \
        libedit-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 
    
# create and activate virtual environment
# using final folder name to avoid path issues with packages
RUN python3.10 -m venv  $VIRTUAL_ENV

ENV PATH="$VIRTUAL_ENV/bin:$PATH" 

RUN pip3 install --no-cache-dir wheel
RUN pip3 install --no-cache-dir \
        jupyterlab \
        ipykernel \
        matplotlib \
        ipywidgets

RUN curl https://get.modular.com | \
        MODULAR_AUTH=$AUTH_KEY \
        sh - \
    && modular install mojo 



FROM ubuntu:22.04 AS runner-image

ARG DEBIAN_FRONTEND=noninteractive \
    MODULAR_HOME=/home/apprunner/.modular \
    VIRTUAL_ENV=/home/apprunner/venv

RUN apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive \
    && apt install --no-install-recommends -y \
        python3.10 \
        python3-venv \
        python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# RUN useradd -ms /bin/bash apprunner && echo "apprunner:toor" | chpasswd && adduser apprunner sudo
RUN useradd -ms /bin/bash apprunner

COPY --from=builder-image /home/apprunner/ /home/apprunner/
    
ENV PYTHONUNBUFFERED=1 \
    MODULAR_HOME=${MODULAR_HOME} \
    PATH="${PATH}:${MODULAR_HOME}/pkg/packages.modular.com_mojo/bin"

ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN chown -R apprunner $MODULAR_HOME

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

USER apprunner
# # Setting the working directory to /app
WORKDIR /app

CMD ["jupyter", "lab", "--ip='*'", "--NotebookApp.token=''", "--NotebookApp.password=''"]
# CMD ["jupyter", "lab", "--ip='*'", "--NotebookApp.token=''", "--NotebookApp.password=''","--allow-root"]

