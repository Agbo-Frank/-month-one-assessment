#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

echo "<h1>Hello from TechCorp!</h1><p>This request is being served by Host: $(hostname)</p>" > /var/www/html/index.html
