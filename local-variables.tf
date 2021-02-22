locals {

    terraform_backend_s3_bucket                     = ""
    terraform_backend_s3_key                        = "terraform.tfstate"

    region                                          = ""
    availability_zone                               = ""

    instance_type                                   = "t3.small"

    budget_notification_subscriber_email_addresses  = ["",""]
    ssh-keypair-name                                = ""
    ssh-keypair-public-key                          = "ssh-rsa"

    home-ip-address-list                            = ["1.2.3.4/32"]

    valheim-server-service-account-password         = ""
    valheim-server-display-name                     = ""
    valheim-server-world-name                       = "Dedicated"
    valheim-server-world-password                   = ""
    valheim-server-public                           = 0

}
