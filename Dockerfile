ARG FROM=pluswerk/php-dev:nginx-7.4

FROM golang:1.11-alpine AS golang

RUN apk add --update git && rm /var/cache/apk/*
RUN go get -u github.com/fogleman/primitive

FROM alpine as dependencies

RUN apk add --update wget tar git && rm /var/cache/apk/*

RUN wget -q https://github.com/imagemin/zopflipng-bin/raw/master/vendor/linux/zopflipng -O /usr/local/bin/zopflipng \
    && chmod 0755 /usr/local/bin/zopflipng \
    && wget -q https://github.com/imagemin/pngcrush-bin/raw/master/vendor/linux/pngcrush -O /usr/local/bin/pngcrush \
    && chmod 0755 /usr/local/bin/pngcrush \
    && wget -q https://github.com/imagemin/jpegoptim-bin/raw/master/vendor/linux/jpegoptim -O /usr/local/bin/jpegoptim \
    && chmod 0755 /usr/local/bin/jpegoptim \
    && wget -q https://github.com/imagemin/pngout-bin/raw/master/vendor/linux/x64/pngout -O /usr/local/bin/pngout \
    && chmod 0755 /usr/local/bin/pngout \
    && wget -q https://github.com/imagemin/advpng-bin/raw/master/vendor/linux/advpng -O /usr/local/bin/advpng \
    && chmod 0755 /usr/local/bin/advpng \
    && wget -q https://github.com/imagemin/mozjpeg-bin/raw/master/vendor/linux/cjpeg -O /usr/local/bin/cjpeg \
    && chmod 0755 /usr/local/bin/cjpeg

RUN cd /tmp && wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
            && tar xvf wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
            && mv wkhtmltox/bin/wkhtmlto* /usr/bin/ \
            && chmod 0755 /usr/bin/wkhtmltopdf \
            && chmod 0755 /usr/bin/wkhtmltoimage \
            && rm -rf wkhtmltox

FROM $FROM as php

COPY --from=golang /go/bin/primitive /usr/local/bin/primitive
COPY --from=dependencies /usr/local/bin/zopflipng /usr/local/bin/zopflipng
COPY --from=dependencies /usr/local/bin/pngcrush /usr/local/bin/pngcrush
COPY --from=dependencies /usr/local/bin/pngout /usr/local/bin/pngout
COPY --from=dependencies /usr/local/bin/advpng /usr/local/bin/advpng
COPY --from=dependencies /usr/local/bin/cjpeg /usr/local/bin/cjpeg
COPY --from=dependencies /usr/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
COPY --from=dependencies /usr/bin/wkhtmltoimage /usr/bin/wkhtmltoimage

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    poppler-utils \
    libimage-exiftool-perl \
    webp \
    inkscape \
    ghostscript \
    ffmpeg \
    graphviz \
    librsvg2-bin \
    libreoffice \
    opencv-data \
    jpegoptim \
    libjpeg-dev \
    libjpeg62-turbo-dev \
    brotli \
    nginx-module-brotli \
    # cleanup
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
            && python3 get-pip.py \
            && rm get-pip.py \
            && git clone https://gitlab.com/wavexx/facedetect.git \
            && pip3 install numpy opencv-python \
            && cd facedetect \
            && cp facedetect /usr/local/bin \
            && cd .. \
            && rm -rf facedetect

RUN docker-service enable postfix

COPY nginx.conf /opt/docker/etc/nginx/vhost.common.d/00-pimcore.conf_deactivated

WORKDIR /app/

