resource "aws_budgets_budget" "valheim-server-cost-budget" {

    name                            = "valheim-server-cost-budget"
    budget_type                     = "COST"
    limit_amount                    = "20.0"
    limit_unit                      = "USD"
    time_period_start               = "2021-01-01_00:00"
    time_unit                       = "MONTHLY"

    notification {
        comparison_operator         = "GREATER_THAN"
        notification_type           = "ACTUAL"
        subscriber_email_addresses  = local.budget_notification_subscriber_email_addresses
        threshold                   = 50
        threshold_type              = "PERCENTAGE"
    }

    notification {
        comparison_operator         = "GREATER_THAN"
        notification_type           = "ACTUAL"
        subscriber_email_addresses  = local.budget_notification_subscriber_email_addresses
        threshold                   = 100
        threshold_type              = "PERCENTAGE"
    }

}

resource "aws_vpc" "valheim-server-vpc" {
    
    cidr_block                      = "10.0.0.0/16"
    enable_dns_hostnames            = true
    enable_dns_support              = true

}

resource "aws_subnet" "valheim-server-public-subnet" {

    availability_zone               = local.availability_zone
    cidr_block                      = "10.0.0.0/24"
    map_public_ip_on_launch         = true
    vpc_id                          = aws_vpc.valheim-server-vpc.id

}

resource "aws_internet_gateway" "valheim-server-internet-gateway" {
    
    vpc_id                          = aws_vpc.valheim-server-vpc.id

}

resource "aws_route_table" "valheim-server-internet-gateway-route-table" {

    vpc_id                          = aws_vpc.valheim-server-vpc.id

    route {
        cidr_block                  = "0.0.0.0/0"
        gateway_id                  = aws_internet_gateway.valheim-server-internet-gateway.id
    }
}

resource "aws_route_table_association" "valheim-server-internet-gateway-route-table-association" {

    subnet_id                       = aws_subnet.valheim-server-public-subnet.id
    route_table_id                  = aws_route_table.valheim-server-internet-gateway-route-table.id

}

resource "aws_security_group" "valheim-server-security-group" {
    
    name                            = "valheim-server-security-group"
    description                     = "Allow inbound Valheim traffic from the internet"
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
        description                 = "SSH from the house"
        from_port                   = 22
        to_port                     = 22
        protocol                    = "tcp"
        cidr_blocks                 = local.home-ip-address-list
    }

    ingress {
        description                 = "Ping from the house"
        from_port                   = 8
        to_port                     = -1
        protocol                    = "icmp"
        cidr_blocks                 = local.home-ip-address-list
    }

}

resource "aws_key_pair" "valheim-server-ssh-keypair" {
  
    key_name                        = local.ssh-keypair-name
    public_key                      = local.ssh-keypair-public-key

}

data "aws_ami" "amazon-linux-2" {

    most_recent                     = true
    owners                          = [ "amazon" ]
    
    filter {
        name                        = "owner-alias"
        values                      = ["amazon"]
    }

    filter {
        name                        = "name"
        values                      = ["amzn2-ami-hvm*"]
    }

}


data "template_file" "user-data-init" {

    template                        = file("user-data.sh")
    vars                            = {
        input                       = "input"
    }

}

resource "aws_instance" "valheim-server-ec2-instance" {

    ami                             = data.aws_ami.amazon-linux-2.id
    instance_type                   = "t2.micro"
    key_name                        = local.ssh-keypair-name
    subnet_id                       = aws_subnet.valheim-server-public-subnet.id
    user_data                       = data.template_file.user-data-init.rendered
    vpc_security_group_ids          = [aws_security_group.valheim-server-security-group.id]

}


# Domain name

# Storage?
