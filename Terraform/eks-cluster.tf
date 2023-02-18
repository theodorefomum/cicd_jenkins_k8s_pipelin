resource "aws_eks_cluster" "max_cluster" {
  name     = "max_prod_cluster"
  role_arn = aws_iam_role.max_iam_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.max_sbn-pub.id]
  }
}

resource "aws_iam_role" "max_iam_role" {
  name = "max_prod_cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.max_iam_role.name
}

resource "aws_iam_role_policy_attachment" "amazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/amazonEKSVPCResourceController"
  role       = aws_iam_role.max_iam_role.name
}


resource "aws_vpc" "max_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "max_vpc"
  }
}

resource "aws_subnet" "max_sbn-pub" {
  vpc_id     = aws_vpc.max_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "max_sbn-priv" {
  vpc_id     = aws_vpc.max_vpc.id
  cidr_block = "10.0.17.0/24"

  tags = {
    Name = "max_sbn-priv"
  }
}

resource "aws_internet_gateway" "max-gw" {
  vpc_id = aws_vpc.max_vpc.id
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.max_vpc.id

  route {
    gateway_id = aws_internet_gateway.max-gw.id
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.max_vpc.id

  ingress {
    description      = "http from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.max_vpc.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.max_vpc.ipv6_cidr_block]
  }
  ingress {
    description      = "http from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.max_vpc.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.max_vpc.ipv6_cidr_block]
  }
  ingress {
    description      = "http from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.max_vpc.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.max_vpc.ipv6_cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_http"
  }
}

resource "aws_eks_node_group" "max-node" {
  cluster_name    = aws_eks_cluster.max_cluster.name
  node_group_name = "max-node"
  node_role_arn   = aws_iam_role.max_iam_role_node.arn
  subnet_ids      = aws_subnet.max_sbn-pub[*].id
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.amazonEKSNodePolicy,
    aws_iam_role_policy_attachment.amazonEKSCNIPolicy,
    aws_iam_role_policy_attachment.amazonEKSec2Policy
  ]
}

resource "aws_iam_role" "max_iam_role_node" {
  name = "max_prod_node_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazonEKSCNIPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.max_iam_role_node.name
}

resource "aws_iam_role_policy_attachment" "amazonEKSNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.max_iam_role_node.name
}

resource "aws_iam_role_policy_attachment" "amazonEKSec2Policy" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.max_iam_role_node.name
}