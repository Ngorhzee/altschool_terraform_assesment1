#! /bin/bash
yum update -y 

yum install -y httpd

systemctl enable httpd
systemctl start httpd

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)
PRIVATE_IP=$(ec2-metadata --local-ipv4 | cut -d " " -f 2)
PUBLIC_IP=$(ec2-metadata --public-ipv4 | cut -d " " -f 2 2>/dev/null || echo "N/A")

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Web Server</title>
</head>
    <body>
    <div class="container">
        <h1>TechCorp Web Application</h1> <br>
        <div class="status">✓ Server is running successfully!</div>
        
        <div class="info-box">
            <h2 style="margin-top: 0;">Server Information</h2>
            <div class="info-item">
                <span class="label">Instance ID:</span>
                <span class="value">$INSTANCE_ID</span>
            </div>
            <div class="info-item">
                <span class="label">Availability Zone:</span>
                <span class="value">$AVAILABILITY_ZONE</span>
            </div>
            <div class="info-item">
                <span class="label">Private IP:</span>
                <span class="value">$PRIVATE_IP</span>
            </div>
            <div class="info-item">
                <span class="label">Server:</span>
                <span class="value">Apache/Amazon Linux 2</span>
            </div>
        </div>
        
        <div class="footer">
            <p>Deployed via Terraform | High Availability Architecture</p>
            <p>© 2025 TechCorp - Cloud Infrastructure</p>
        </div>
    </div>
</body>
</html>
EOF

useradd -m ${var.ssh_username}
echo "${var.ssh_username}:${var.ssh_password}" | chpasswd
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g'  /etc/ssh/sshd_config
systemctl restart sshd
echo "${var.ssh_username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${var.ssh_username}