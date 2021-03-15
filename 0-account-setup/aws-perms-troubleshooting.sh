# Script straight from AWS
( echo "Time,Identity ARN,Event ID,Service,Action,Error,Message";
  aws cloudtrail lookup-events --start-time "2019-10-29T06:40:00Z" --end-time "2019-10-29T06:55:00Z" --query "Events[*].CloudTrailEvent" --output text \
    | jq -r ". | select(.userIdentity.arn == \"your-arn\" and .eventType == \"AwsApiCall\" and .errorCode != null
    and (.errorCode | ascii_downcase | (contains(\"accessdenied\") or contains(\"unauthorized\"))))
    | [.eventTime, .userIdentity.arn, .eventID, .eventSource, .eventName, .errorCode, .errorMessage] | @csv"
) | column -t -s'",'


# Show all events from terraform-deployment-user
# Pro tip: run aws configure and set the default region to the region you're working in
( echo "Time,Identity ARN,Event ID,Service,Action,Error,Message";
  aws cloudtrail lookup-events --query "Events[*].CloudTrailEvent" --output text \
    | jq -r ". | select(.userIdentity.arn == \"arn:aws:iam::861106365932:user/terraform-deployment-user\")
    | [.eventTime, .userIdentity.arn, .eventID, .eventSource, .eventName, .errorCode, .errorMessage] | @csv"
) | column -t -s'",'


# Script straight from AWS, with terraform-deployment-user ARN filled in
( echo "Time,Identity ARN,Event ID,Service,Action,Error,Message";
  aws cloudtrail lookup-events --query "Events[*].CloudTrailEvent" --output text \
    | jq -r ". | select(.userIdentity.arn == \"arn:aws:iam::861106365932:user/terraform-deployment-user\" and .eventType == \"AwsApiCall\" and .errorCode != null
    and (.errorCode | ascii_downcase | (contains(\"accessdenied\") or contains(\"unauthorized\"))))
    | [.eventTime, .userIdentity.arn, .eventID, .eventSource, .eventName, .errorCode, .errorMessage] | @csv"
) | column -t -s'",'


# Uniq
( echo "Service,Action,Error,Message";
  aws cloudtrail lookup-events --query "Events[*].CloudTrailEvent" --output text \
    | jq -r ". | select(.userIdentity.arn == \"arn:aws:iam::861106365932:user/terraform-deployment-user\" and .eventType == \"AwsApiCall\" and .errorCode != null
    and (.errorCode | ascii_downcase | (contains(\"accessdenied\") or contains(\"unauthorized\"))))
    | [.eventSource, .eventName, .errorCode, .errorMessage] | @csv"
) | uniq | column -t -s'",'


# 
( echo "Time,Service,Action,Error,Message";
  aws cloudtrail lookup-events  --query "Events[*].CloudTrailEvent" --output text \
    | jq -r ". | select(.userIdentity.arn == \"arn:aws:iam::861106365932:user/terraform-deployment-user\" and .eventType == \"AwsApiCall\" and .errorCode != null
    and (.errorCode | ascii_downcase | (contains(\"accessdenied\") or contains(\"unauthorized\"))))
    | [.eventTime, .eventSource, .eventName, .errorCode, .errorMessage] | @csv"
)  | column -t -s'",'


aws sts decode-authorization-message --encoded-message \
 \
--query DecodedMessage --output text | jq -r ".context.action"

aws sts decode-authorization-message --encoded-message \
tCjGQaStNVZ_-VGV20AKU3udIactba9BnnZXbRn99IhthqTJ2I4IKbbweELdEa2AyvEj-MHouwRZMU06frrTZRMtB62Fg-FEyjQAAjCuUzHJH7X9Pnt7yVPTu-iHR0QUYbanLaeNpExQbMuMfI6KbVEB_0jZnCE1RwsrNKnQQznCvcmueM0arDCT9Da-Oe0sqp2r-nyoIr9C7zDzazj_sS7HPp5vnSl_SYPh-edenyh0EZaJnAAte2LOA0_OnBLBBj_zY4IFPTvAlI1Q1a-x1MiC9Enn0XqNIZWv9Vtwpmp24zFSKkq-0c6SXvfRrSnitgvgLvCbPfP9Z9fvp0YQW1lP70Hnkbi1Sn69_68AYuLlq0U_49oy2GwjXTOAQEUPnuEjbRzWXGkHnez50hpGkqWFZrHtFLRJRnUxeTkX9qW3Ni7gLYGN4VCYA9pdo7FhxnMWASunotlij9xg6AvcGDS85YYM0HeisUbiNGXyV-Xpe0uKNPrudOdOQcGO__oIx33Zjgt0fnXDFglVUxU \
--query DecodedMessage --output text | jq -r ".context.action"

# SSH command
ssh -i ~/.ssh/id_rsa_aws_valheim ec2-user@$(terraform14 output -json ec2-instance-public-dns-name | jq . -r)
ssh -i ~/.ssh/id_rsa_aws_valheim ec2-user@ec2-52-24-68-233.us-west-2.compute.amazonaws.com

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa_aws_valheim ec2-user@$(terraform14 output -raw ec2-instance-public-dns-name)

terraform14 apply --auto-approve && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa_aws_valheim ec2-user@server.valheimlich.link "tail -f /var/log/valheim-server-terraform-bootstrap.log" || nc -z server.valheimlich.link 22 && ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa_aws_valheim ec2-user@server.valheimlich.link