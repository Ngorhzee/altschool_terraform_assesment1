#!/bin/bash

# Update system
yum update -y

# Install Apache
yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Install PostgreSQL
amazon-linux-extras enable postgresql13
yum install -y postgresql postgresql-server
postgresql-setup --initdb

# Configure authentication
sed -i "s/ident/md5/" /var/lib/pgsql/data/pg_hba.conf
sed -i "s/peer/md5/" /var/lib/pgsql/data/pg_hba.conf
echo "host    all             all             10.0.0.0/16            md5" >> /var/lib/pgsql/data/pg_hba.conf

# Start Postgres
systemctl enable postgresql
systemctl start postgresql

until pg_isready -U postgres; do
  echo "Waiting for Postgres to start..."
  sleep 5
done
# ensure DB is fully started

# Create DB and user
sudo -u postgres psql -c "CREATE DATABASE techcorp_db;"
sudo -u postgres psql -c "CREATE USER techcorp_main WITH ENCRYPTED PASSWORD 'Tech2025!';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE techcorp_db TO techcorp_main;"

systemctl restart postgresql
# Create SSH user
useradd -m ${var.ssh_username}
echo "${var.ssh_username}:${var.ssh_password}" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "${var.ssh_username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${var.ssh_username}
