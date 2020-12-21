FROM mysql:5.6

RUN mkdir -p /var/log/mysql && touch /var/log/mysql/slow-queries.log && touch /var/log/mysql/safe-err.log && \
touch /var/log/mysql/mysqld.log && chown -R mysql:mysql /var/log/mysql
