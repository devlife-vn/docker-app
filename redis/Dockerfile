FROM redis:latest

RUN rm -r ${DATA_PATH_HOST}/redis
RUN mkdir ${DATA_PATH_HOST}/redis

VOLUME /data

EXPOSE 6379

CMD ["redis-server"]