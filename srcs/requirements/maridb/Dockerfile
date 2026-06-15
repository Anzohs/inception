FROM debian::bullseye

RUN apt-get update && apt-get install -y mariadb-server

COPY tools/setup.sh	/

RUN chmod +x /setup.sh

CMD ["/setup.sh"]
