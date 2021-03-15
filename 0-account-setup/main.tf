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
