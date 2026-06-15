FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y \
    php-fpm \
    php-mysql \
    wget

COPY tools/setup.sh /

RUN chmod +x /setup.sh

CMD ["/setup.sh"]
