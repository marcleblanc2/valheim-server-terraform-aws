# Budgets
resource "aws_budgets_budget" "cost" {
    name              = "cost-budget"
    budget_type       = "COST"
    limit_amount      = "20"
    limit_unit        = "USD"
    time_unit         = "MONTHLY"
    time_period_start = "2021-01-01_00:00"

    notification {
        comparison_operator        = "GREATER_THAN"
        threshold                  = 50
        threshold_type             = "PERCENTAGE"
        notification_type          = "ACTUAL"
        subscriber_email_addresses = local.budget_notification_subscriber_email_addresses
    }

    notification {
        comparison_operator        = "GREATER_THAN"
        threshold                  = 100
        threshold_type             = "PERCENTAGE"
        notification_type          = "ACTUAL"
        subscriber_email_addresses = local.budget_notification_subscriber_email_addresses
    }
}

# VPC?

# Free linux instance

# Domain name

# Storage?
