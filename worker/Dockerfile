FROM python:3.8-alpine

LABEL version="0.0.1"

RUN apk add --update-cache \
    build-base \
    cmake \
    jpeg-dev \
    py-pip \
    zlib-dev \
    && pip install --upgrade pip \
    && rm -rf /var/cache/apk/*

COPY requirements.txt .

RUN pip install -r requirements.txt

RUN adduser -D worker

USER worker

WORKDIR /home/worker

COPY . .

ENTRYPOINT python worker.py

VOLUME ["/source-images", "/blurred-images"]