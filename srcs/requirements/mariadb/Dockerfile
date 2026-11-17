FROM debian:12

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-server && rm -rf /var/lib/apt/lists/* /var/lib/mysql && install -d -o mysql -g mysql /run/mysqld /var/lib/mysql

COPY tools/entrypoint.sh /usr/local/bin/mariadb-entrypoint
COPY tools/healthcheck.sh /usr/local/bin/mariadb-healthcheck

RUN chmod 0755 /usr/local/bin/mariadb-entrypoint /usr/local/bin/mariadb-healthcheck

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint"]
