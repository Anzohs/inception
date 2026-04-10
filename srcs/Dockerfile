# configuration for NGINX

#image from base for NGIX
FROM alpline:3.18

#the openssl is necessary for the network
# it will generate certificates for HTTPS communications
RUN apk add --no-chache nginx openssl

#copy configuration file
COPY ./nginx.conf /etc/nginx/nginx.conf

#Copy certificates
COPY ./ssl /ect/nginx/ssl

#port for HTTPS
EXPOSE 443

#start NGINX
# -g flag that allows pass global directives no nginx
# daemon is off go it keeps the container alive during the nginx lifecycle!
CMD [ "nginx", "-g", "daemon off;" ]
