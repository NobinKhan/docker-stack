FROM chainguard/wolfi-base:latest

ENV LANG="en_US.utf8"
ENV LC_ALL="en_US.utf8"
ENV PGDATA="/var/lib/postgresql/data"

RUN set -eux; \
	apk update --no-cache ;\
	apk upgrade --no-cache ;\
	addgroup -g 70 -S postgres; \
	adduser -u 70 -S -D -G postgres -H -h /var/lib/postgresql -s /bin/sh postgres; \
	install --verbose --directory --owner postgres --group postgres --mode 1777 /var/lib/postgresql ;\
	apk add --no-cache \
		ca-certificates \
		bash \
		zstd \
		gosu \
		pgaudit-17 \
		postgresql-17 \
		postgresql-17-client \
		postgresql-17-contrib \
		postgresql-17-oci-entrypoint ;\
	postgres --version ;\
	install --verbose --directory --owner postgres --group postgres --mode 1777 "$PGDATA"

VOLUME /var/lib/postgresql/data
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
STOPSIGNAL SIGINT
EXPOSE 5432

CMD ["postgres"]
