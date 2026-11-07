FROM python:3.12.7-alpine

RUN apk add --no-cache openssh-client sshpass
RUN pip install --no-cache-dir ansible-core==2.18.1

WORKDIR /workspace
