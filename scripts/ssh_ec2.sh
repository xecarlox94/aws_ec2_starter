ssh ubuntu@$(terraform output -raw public_ip) -i ~/.ssh/id_rsa.pub
