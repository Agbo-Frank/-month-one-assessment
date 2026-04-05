#!/bin/bash
yum update -y
amazon-linux-extras enable postgresql15

yum install -y postgresql-server

postgresql-setup initdb


systemctl start postgresql
systemctl enable postgresql

sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf

# 7. Restart to apply configuration changes
systemctl restart postgresql