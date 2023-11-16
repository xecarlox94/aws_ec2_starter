
mkdir .ssh


ssh-keygen -t rsa -b 2048 -f $PWD/.ssh/aws


sudo chmod 600 .ssh/aws
sudo chmod 600 .ssh/aws.pub
