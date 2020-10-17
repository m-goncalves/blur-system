FROM python:3.8-slim

LABEL version="0.0.1"

RUN apt update && apt install -y \
    cmake \
    g++ \
    ruby-full \
    && pip install --upgrade pip \
    && pip install face-recognition
    
RUN gem install bunny --version ">= 2.13.0"

WORKDIR /app

COPY . .

ENTRYPOINT ruby blurImage.rb

VOLUME ["/source-images", "/blurred-images"]