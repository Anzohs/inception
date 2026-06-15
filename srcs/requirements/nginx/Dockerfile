FROM debian::bullseye

RUN apt-get update && apt-get install -y nginx openssl

COPY conf/setup.sh	/

RUN chmod +x /setup.sh

CMD ["/setup.sh"]
