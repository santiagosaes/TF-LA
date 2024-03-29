resource "aws_instance" "instance_1" {
  #count = length(var.private_subnet_cidr_blocks)
  ami             = var.ami
  instance_type   = var.instance_type
  subnet_id = aws_subnet.private[1].id
  security_groups = [aws_security_group.instances.id]
  
  user_data       =   <<-EOF
              /*#!/bin/bash
              echo "Hello, World 1" > index.html
              python3 -m http.server 8080 &
              EOF
  /*user_data = <<-EOF
  #!/bin/bash -ex
  amazon-linux-extras install nginx1 -y
  echo "<h1>$(curl https://api.kanye.rest/?format=text)</h1>" >  /usr/share/nginx/html/index.html 
  systemctl enable nginx
  systemctl start nginx
  EOF*/

  tags = {
    "Name" : "LiderApp1"
  }      
}

resource "aws_instance" "instance_2" {
  ami             = var.ami
  instance_type   = var.instance_type
  subnet_id = aws_subnet.private[0].id
  security_groups = [aws_security_group.instances.id]
  #security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 2" > index.html
              python3 -m http.server 8080 &
              EOF
  tags = {
    "Name" : "LiderApp2"
  }
}
