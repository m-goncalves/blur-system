FROM mysql/mysql-server:latest

RUN touch /var/run/mysqld/mysqld.sock \
    && touch /var/run/mysqld/mysqld.pid \
    && chown mysql:mysql /var/run/mysqld/mysqld.sock \
    && chown mysql:mysql /var/run/mysqld/mysqld.pid \
    && chmod -R 644 /var/run/mysqld/mysqld.sock

COPY script/ /docker-entrypoint-initdb.d/