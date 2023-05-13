# data call for available azs in the region:
data "aws_availability_zones" "azs" {
  state = "available"
}

# data call for aws secrets manager secret:
data "aws_secretsmanager_secret_version" "credentials" {
  secret_id = "rds_credentials"
}

# lookup latest amazon-linux-2 AMIs:
data "aws_ami" "amazon-linux-2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.*-x86_64-gp2"]
  }
}

locals {
  public_1a_subnet_id   = module.subnets.subnet_ids[2]
  public_1b_subnet_id   = module.subnets.subnet_ids[3]
  private_1a_subnet_id  = module.subnets.subnet_ids[0]
  private_1b_subnet_id  = module.subnets.subnet_ids[1]
  public_1a_instance_id = module.public-ec2.ec2_ids[0]
  public_1b_instance_id = module.public-ec2.ec2_ids[1]
  rds_credentials       = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)
}

# create vpc with igw:
module "vpc" {
  source                = "./vpc_module"
  vpc_cidr_block        = "10.0.0.0/24"
  vpc_tag               = "project_vpc"
  create_and_attach_igw = true
}

# create subnets:
module "subnets" {
  source = "./subnet_module"
  vpc_id = module.vpc.vpc_id
  subnets = { # map, or dictionary, or object
    "public_1a"  = ["10.0.0.0/26", data.aws_availability_zones.azs.names[0], true]
    "public_1b"  = ["10.0.0.64/26", data.aws_availability_zones.azs.names[1], true]
    "private_1a" = ["10.0.0.128/26", data.aws_availability_zones.azs.names[0], false]
    "private_1b" = ["10.0.0.192/26", data.aws_availability_zones.azs.names[1], false]
  }
}

# create natgw:
module "natgw" {
  source          = "./natgw_module"
  eip_tag         = "project_eip"
  nat_gateway_tag = "project_natgw"
  subnet_id       = module.subnets.subnet_ids[2]
}

# create public_rtb:
module "public_rtb" {
  source     = "./route_table_module"
  vpc_id     = module.vpc.vpc_id
  gateway_id = module.vpc.igw_id
  subnet_ids = [module.subnets.subnet_ids[2], module.subnets.subnet_ids[3]]
}

# create private_rtb:
module "private_rtb" {
  source         = "./route_table_module"
  vpc_id         = module.vpc.vpc_id
  nat_gateway_id = module.natgw.natgw_id
  subnet_ids     = [module.subnets.subnet_ids[0], module.subnets.subnet_ids[1]]
}

# # for challenge lovers, make rtb module all-in-one(one call creates x number of route tables):
# # rough example:
# module "route_tables" {
#     source = "./subnet_module"
#     "public_rtb" = [module.vpc.vpc_id, module.vpc.igw_id, [module.subnets.subnet_ids[2], module.subnets.subnet_ids[3]]]
#     "private_rtb" = [module.vpc.vpc_id, module.natgw.natgw_id, [module.subnets.subnet_ids[0], module.subnets.subnet_ids[1]]]
# }

# create public ec2 sg:
module "public_sg" {
  source  = "./sg_module"
  vpc_id  = module.vpc.vpc_id
  sg_name = "project-ec2-sg"
  sg_tag  = "project-ec2-sg"

  sg_rules = {
    "allow ssh from www" : ["ingress", "0.0.0.0/0", 22, 22, "TCP"]
    "allow http from www" : ["ingress", module.alb_sg.sg_id, 80, 80, "TCP"]
    "allow outbound traffic to www" : ["egress", "0.0.0.0/0", 0, 65535, "-1"]
  }
}

# create alb sg:
module "alb_sg" {
  source  = "./sg_module"
  vpc_id  = module.vpc.vpc_id
  sg_name = "project-alb-sg"
  sg_tag  = "project-alb-sg"

  sg_rules = {
    "allow http from www" : ["ingress", "0.0.0.0/0", 80, 80, "TCP"]
    "allow https from www" : ["ingress", "0.0.0.0/0", 443, 443, "TCP"]
    "allow outbound traffic to www" : ["egress", "0.0.0.0/0", 0, 65535, "-1"]
  }
}

# create database sg:
module "db_sg" {
  source  = "./sg_module"
  vpc_id  = module.vpc.vpc_id
  sg_name = "project-rds-sg"
  sg_tag  = "project-rds-sg"

  sg_rules = {
    "allow 3306 from ec2" : ["ingress", module.public_sg.sg_id, 3306, 3306, "TCP"]
    "allow outbound traffic to www" : ["egress", "0.0.0.0/0", 0, 65535, "-1"]
  }
}

# in plain resource creating ssh key we have previously generated:
resource "aws_key_pair" "my_ssh-keygened_key" {
  key_name   = "project_key"
  public_key = file("~/.ssh/id_rsa.pub")

  tags = {
    Name = "project_key"
  }
}

module "public-ec2" {
  source        = "./ec2_module"
  ami           = data.aws_ami.amazon-linux-2_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_ssh-keygened_key.key_name
  ec2_sg        = [module.public_sg.sg_id]
  user_data     = <<EOT
    #!/bin/bash
    yum update -y
    yum install httpd -y
    echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html 
    systemctl start httpd
    systemctl enable httpd
    EOT

  instances = {
    "public-1a-ec2" : module.subnets.subnet_ids[2]
    "public-1b-ec2" : module.subnets.subnet_ids[3]
  }
}

module "public_ec2_tg" {
  source       = "./target_group_module"
  tg_name      = "public-ec2-tg"
  tg_port      = 80
  tg_protocol  = "HTTP"
  tg_vpc_id    = module.vpc.vpc_id
  tg_tag       = "project-public-ec2-tg"
  instance_ids = [local.public_1a_instance_id, local.public_1b_instance_id]
}

module "alb" {
  source                                = "./alb_module"
  alb_name                              = "project-alb"
  load_balancer_type                    = "application"
  alb_sg                                = [module.alb_sg.sg_id]
  alb_subnets                           = [local.public_1a_subnet_id, local.public_1b_subnet_id]
  alb_tag                               = "project_alb"
  alb_https_listener_certificate_domain = "rustemtentech.com"
  target_group_arn                      = module.public_ec2_tg.tg_arn
}

# create route 53 record
module "dns_record" {
  source         = "./dns_module"
  hosted_zone    = "rustemtentech.com"
  record_name    = "eight.rustemtentech.com"
  record_type    = "CNAME"
  record_ttl     = 120
  record_records = [module.alb.dns_name]
}

# create rds:
module "database" {
  source                     = "./database_module"
  db_subnet_group_name       = "db-subnet-group"
  db_subnet_group_subnet_ids = [local.private_1a_subnet_id, local.private_1b_subnet_id]
  db_subnet_group_tag        = "db_subnet_group"
  allocated_storage          = 20
  engine                     = "mysql"
  engine_version             = "5.7.37"
  instance_class             = "db.t3.micro"
  db_name                    = "projectRds"
  username                   = local.rds_credentials.username
  password                   = local.rds_credentials.password
  security_group_ids         = [module.db_sg.sg_id]
}
