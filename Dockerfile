FROM alpine:latest

RUN apk update && apk --no-cache add curl jq

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x ./entrypoint.sh

VOLUME [ "/config" ]

CMD ["/entrypoint.sh"]
