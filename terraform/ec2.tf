data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app1" {
  ami                         = data.aws_ami.amazon_linux2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true
  user_data                   = templatefile("${path.module}/ec2_user_data.tpl", { domain = var.domain_name, name = "ec2-instance1" })
  tags = { Name = "${var.project}-${var.environment}-ec2-1" }
}

resource "aws_eip" "app1_eip" {
  instance = aws_instance.app1.id
}

resource "aws_instance" "app2" {
  ami                         = data.aws_ami.amazon_linux2.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[1].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true
  user_data                   = templatefile("${path.module}/ec2_user_data.tpl", { domain = var.domain_name, name = "ec2-instance2" })
  tags = { Name = "${var.project}-${var.environment}-ec2-2" }
}

resource "aws_eip" "app2_eip" {
  instance = aws_instance.app2.id
}

# Template file ec2_user_data.tpl will be created in same folder (see below)
