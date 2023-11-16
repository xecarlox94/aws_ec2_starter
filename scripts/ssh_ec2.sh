ssh ubuntu@$(terraform output -raw public_ip) -i .ssh/aws.pub
