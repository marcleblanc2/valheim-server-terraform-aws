# resource "aws_budgets_budget" "valheim-server-cost-budget" {

#     name                            = "valheim-server-cost-budget"
#     budget_type                     = "COST"
#     limit_amount                    = "20.0"
#     limit_unit                      = "USD"
#     time_period_start               = "2021-01-01_00:00"
#     time_unit                       = "MONTHLY"

#     notification {
#         comparison_operator         = "GREATER_THAN"
#         notification_type           = "ACTUAL"
#         subscriber_email_addresses  = local.budget_notification_subscriber_email_addresses
#         threshold                   = 50
#         threshold_type              = "PERCENTAGE"
#     }

#     notification {
#         comparison_operator         = "GREATER_THAN"
#         notification_type           = "ACTUAL"
#         subscriber_email_addresses  = local.budget_notification_subscriber_email_addresses
#         threshold                   = 100
#         threshold_type              = "PERCENTAGE"
#     }

# }

resource "aws_vpc" "valheim-server-vpc" {
    
    cidr_block                      = "10.0.0.0/16"
    enable_dns_hostnames            = true
    enable_dns_support              = true
    tags                            = local.tags

}

resource "aws_subnet" "valheim-server-public-subnet" {

    availability_zone               = local.availability_zone
    cidr_block                      = "10.0.0.0/24"
    map_public_ip_on_launch         = true
    tags                            = local.tags
    vpc_id                          = aws_vpc.valheim-server-vpc.id

}

resource "aws_internet_gateway" "valheim-server-internet-gateway" {
    
    tags                            = local.tags
    vpc_id                          = aws_vpc.valheim-server-vpc.id

}

resource "aws_route_table" "valheim-server-internet-gateway-route-table" {

    tags                            = local.tags
    vpc_id                          = aws_vpc.valheim-server-vpc.id

    route {
        cidr_block                  = "0.0.0.0/0"
        gateway_id                  = aws_internet_gateway.valheim-server-internet-gateway.id
    }
}

resource "aws_route_table_association" "valheim-server-internet-gateway-route-table-association" {

    route_table_id                  = aws_route_table.valheim-server-internet-gateway-route-table.id
    subnet_id                       = aws_subnet.valheim-server-public-subnet.id

}

resource "aws_security_group" "valheim-server-security-group" {
    
    description                     = "Allow inbound Valheim traffic from the internet"
    name                            = "valheim-server-security-group"
    tags                            = local.tags
    vpc_id                          = aws_vpc.valheim-server-vpc.id

    egress {
        description                 = "Access to the internet"
        from_port                   = 0
        to_port                     = 0
        protocol                    = "-1"
        cidr_blocks                 = ["0.0.0.0/0"]
    }

    ingress {
        description                 = "UDP 2456-2458 from the internet"
        from_port                   = 2456
        to_port                     = 2458
        protocol                    = "udp"
        cidr_blocks                 = ["0.0.0.0/0"]
    }

    ingress {
        description                 = "SSH inbound"
        from_port                   = 22
        to_port                     = 22
        protocol                    = "tcp"
        cidr_blocks                 = local.management-ip-address-list
    }

    ingress {
        description                 = "Ping inbound"
        from_port                   = 8
        to_port                     = -1
        protocol                    = "icmp"
        cidr_blocks                 = local.management-ip-address-list
    }

}

resource "aws_key_pair" "valheim-server-ssh-keypair" {
  
    key_name                        = local.ssh-keypair-name
    public_key                      = local.ssh-keypair-public-key
    tags                            = local.tags

}

data "aws_ami" "amazon-linux-2" {

    most_recent                     = true
    owners                          = ["amazon"]
    
    filter {
        name                        = "name"
        values                      = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name                        = "description"
        values                      = ["Amazon Linux 2 AMI * x86_64 HVM gp2"]
    }

}

data "template_file" "user-data-init" {

    template                        = file("user-data.sh")
    vars                            = {
        environment                             = terraform.workspace
        game-data-bucket-name                   = local.game-data-bucket-name
        region                                  = local.region
        valheim-server-display-name             = local.valheim-server-display-name
        valheim-server-world-name               = local.valheim-server-world-name
        valheim-server-world-password           = local.valheim-server-world-password
        valheim-server-public                   = local.valheim-server-public
        svc_account                             = local.svc_account
    }

}

resource "aws_instance" "valheim-server-ec2-instance" {

    ami                             = data.aws_ami.amazon-linux-2.id
    iam_instance_profile            = local.iam_instance_profile
    instance_type                   = local.instance_type
    key_name                        = local.ssh-keypair-name
    subnet_id                       = aws_subnet.valheim-server-public-subnet.id
    tags                            = local.tags
    user_data                       = data.template_file.user-data-init.rendered
    vpc_security_group_ids          = [aws_security_group.valheim-server-security-group.id]

}

resource "aws_route53_record" "valheim-server-route53-record" {

    name                            = local.route53-hostname
    records                         = [aws_instance.valheim-server-ec2-instance.public_dns] 
    type                            = "CNAME"
    ttl                             = "60"
    zone_id                         = local.route53-zone-id

}
