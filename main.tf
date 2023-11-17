terraform {

#   cloud {
#       organization = "nr-tmp-org"
#       workspaces {
#           name = "nr-ai-pipeline"
#       }
#   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.6.3"
}

provider "aws" {
    region  = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*22*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "vpc" {
    cidr_block              = var.cidr_vpc
    enable_dns_support      = true
    enable_dns_hostnames    = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public" {
    vpc_id     = aws_vpc.vpc.id
    cidr_block = var.cidr_subnet
}

resource "aws_route_table" "rtb_public" {
    vpc_id      = aws_vpc.vpc.id

    route {
        cidr_block  = "0.0.0.0/0"
        gateway_id  = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "rta_subnet_public" {
    subnet_id       = aws_subnet.subnet_public.id
    route_table_id  = aws_route_table.rtb_public.id
}

resource  "aws_security_group" "sg" {
    name   = "sg"
    vpc_id = aws_vpc.vpc.id

    # SSH access from the VPC
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "tls_private_key" "pk" {
    algorithm   = "RSA"
    rsa_bits    = 4096
}

resource "local_sensitive_file" "pem_file" {
    content                 = tls_private_key.pk.private_key_pem
    filename                = "${path.module}/.ssh/ec2.pem"
}

resource "aws_key_pair" "ssh_key" {
    key_name    = "myKey"
    public_key  = tls_private_key.pk.public_key_openssh
}


resource "aws_instance" "app_server" {

    key_name        = aws_key_pair.ssh_key.key_name

    ami             = data.aws_ami.ubuntu.id
    instance_type   = "t2.micro"

    subnet_id                   = aws_subnet.subnet_public.id
    vpc_security_group_ids      = [aws_security_group.sg.id]
    associate_public_ip_address = true

    tags = {
        Name = var.instance_name
    }

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = tls_private_key.pk.private_key_pem
        host        = self.public_ip
    }

    provisioner "file" {
        source      = "scripts/init_script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo chmod +x /tmp/script.sh",
            "sudo /tmp/script.sh"
        ]
    }

}

