terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
}

resource "aws_instance" "Demo" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name= "aws_key"
  vpc_security_group_ids = [aws_security_group.main.id]
  
  provisioner "remote-exec" {
    inline = [
      "touch hello.txt",
      "echo helloworld remote provisioner >> hello.txt",
    ]
  }
  connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("/home/jmauney/aws_key")
      timeout     = "4m"
   }
  
  user_data = <<-EOL
  #!/bin/bash

  apt-get update
  apt-get install -y cloud-utils apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install -y docker-ce
  usermod -aG docker ubuntu

  curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  EOL

  tags = {
    Name = "TFDemo"
  }
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "tcp"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}


resource "aws_key_pair" "deployer" {
  key_name   = "aws_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbvRN/gvQBhFe+dE8p3Q865T/xTKgjqTjj56p1IIKbq8SDyOybE8ia0rMPcBLAKds+wjePIYpTtRxT9UsUbZJTgF+SGSG2dC6+ohCQpi6F3xM7ryL9fy3BNCT5aPrwbR862jcOIfv7R1xVfH8OS0WZa8DpVy5kTeutsuH5suehdngba4KhYLTzIdhM7UKJvNoUMRBaxAqIAThqH9Vt/iR1WpXgazoPw6dyPssa7ye6tUPRipmPTZukfpxcPlsqytXWlXm7R89xAY9OXkdPPVsrQdkdfhnY8aFb9XaZP8cm7EOVRdxMsA1DyWMVZOTjhBwCHfEIGoePAS3jFMqQjGWQd rahul@rahul-HP-ZBook-15-G2"
}

