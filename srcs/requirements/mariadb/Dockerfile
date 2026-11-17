FROM debian:12

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-server && rm -rf /var/lib/apt/lists/*

COPY tools/entrypoint.sh /usr/local/bin/mariadb-entrypoint
COPY tools/healthcheck.sh /usr/local/bin/mariadb-healthcheck

RUN chmod 0755 /usr/local/bin/mariadb-entrypoint /usr/local/bin/mariadb-healthcheck && mkdir -p /run/mysqld /var/lib/mysql && chown -R mysql:mysql /run/mysqld /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint"]
