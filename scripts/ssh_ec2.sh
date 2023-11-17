ssh ubuntu@$(terraform output -raw public_ip) \
    -i ".ssh/ec2.pem"
