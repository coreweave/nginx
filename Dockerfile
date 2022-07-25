FROM debian:stable AS builder

LABEL maintainer="Matt Campbell <mcampbell@coreweave.com>"

ARG MOD_ZIP_VERSION=5b2604b3914f87db2077f2239b8a98b66cf622af
ARG NGINX_VERSION=1.23.1
ARG build_dir="/usr/share/tmp"
ARG nginx_module_dir="/usr/local/nginx/modules/"
ARG USER=1001

# Setup
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  ca-certificates \
  wget \
  git \
  build-essential \
  libpcre3-dev \
  zlib1g-dev \
  libzstd-dev
RUN mkdir -p ${build_dir}

# Download NGINX
RUN cd ${build_dir} \
  && wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar zxf nginx-${NGINX_VERSION}.tar.gz \
  && rm nginx-${NGINX_VERSION}.tar.gz

# Download Modules
RUN cd ${build_dir} \
  && git clone --recursive https://github.com/evanmiller/mod_zip mod_zip \
    && cd mod_zip \
    && git checkout $MOD_ZIP_VERSION

# Install modules
RUN cd ${build_dir}/nginx-${NGINX_VERSION} \
  && ./configure --with-compat \
  --add-dynamic-module=../mod_zip \
  && make && make install

# Move compiled modules
RUN chmod -R 644 ${nginx_module_dir}

FROM nginxinc/nginx-unprivileged:1.23.1
ARG USER
ARG nginx_module_dir="/usr/local/nginx/modules/"
COPY --from=builder ${nginx_module_dir}/ngx_http_zip_module.so /etc/nginx/modules/

USER root

RUN chmod 0777 /var/cache/nginx/

USER $USER