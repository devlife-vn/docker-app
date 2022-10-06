# author: quandn
FROM redis:latest

# RUN rm -r ${DATA_PATH_HOST}/redis
RUN mkdir ${DATA_PATH_HOST}/redis

# For security settings uncomment, make the dir, copy conf, and also start with the conf, to use it
RUN mkdir -p /usr/local/etc/redis
COPY redis.conf /usr/local/etc/redis/redis.conf

VOLUME /data

EXPOSE 6379

CMD ["redis-server"]