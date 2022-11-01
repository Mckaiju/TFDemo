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
      "echo hello world! >> hello.txt",
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
  docker pull hello-world
  dock run hello-world
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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOmhpZRRm6yBoCbcjxrYhR4ZJyZAFHRPE36xL2i5OpXk6ieEUi0q80whxpUsyQMrQc8UrzuOcKpNAKb4YFg80Yph1eIa9Id0wSXBoNTsdZaaWvwtCms+YKP+ELjlR3uJwlci0QajAnxZB4sukFNWSWqCo1QCsl+JE860I7te1g57jYOtqDzuLXotrETyF9MLRhge0BNViO3zFJ2TmEAJb7GPdhceGVAUHi+0wm8+VzozBMJMf50DBwg90JNROTMjrkiP8Ur9nAbQURrpbh6U6QtsQTPbN8MR99IHb44SUxQfylEhfImy9WcKWbFgAyRg1SlSGQRr2Fs1J0gK+yn6rj jmauney@DESKTOP-CFM4EJ9"
}

