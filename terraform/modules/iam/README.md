# AWS IAM Terraform Module

This module provisions AWS IAM resources including roles, policies, and instance profiles, following AWS best practices.

## Features

- Creates IAM roles with customizable trust relationships
- Supports policy creation with inline statements or policy documents
- Creates instance profiles for EC2 instances
- Supports MFA enforcement for role assumption
- Highly customizable through variables

## Usage

### Basic Role with Managed Policies

```terraform
module "iam" {
  source = "./terraform/modules/iam"

  name = "web-app"
  
  # Role configuration
  trusted_role_services = ["ec2.amazonaws.com"]
  
  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  
  # Create instance profile
  create_instance_profile = true
  
  tags = {
    Environment = "dev"
    Project     = "web-app"
  }
}
```

### Role with Custom Policy

```terraform
module "iam" {
  source = "./terraform/modules/iam"

  name = "api-service"
  
  # Role configuration
  trusted_role_services = ["ec2.amazonaws.com"]
  
  # Create custom policies
  policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = [
            "arn:aws:s3:::my-bucket/*"
          ]
        }
      ]
    }),
    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem",
            "dynamodb:Query"
          ]
          Resource = [
            "arn:aws:dynamodb:eu-west-1:123456789012:table/my-table"
          ]
        }
      ]
    })
  }
  
  # Create instance profile
  create_instance_profile = true
  
  tags = {
    Environment = "production"
    Project     = "api"
  }
}
```

### Role with MFA Requirement

```terraform
module "iam" {
  source = "./terraform/modules/iam"

  name = "admin-role"
  
  # Role configuration
  trusted_role_arns = ["arn:aws:iam::123456789012:user/admin-user"]
  mfa_required      = true
  
  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  
  tags = {
    Environment = "production"
    Purpose     = "administration"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the IAM role | string | n/a | yes |
| name_prefix | Prefix to add to IAM role name | string | null | no |
| path | Path of IAM role | string | "/" | no |
| description | Description of IAM role | string | "IAM role managed by Terraform" | no |
| max_session_duration | Maximum session duration (in seconds) for the role | number | 3600 | no |
| force_detach_policies | Whether to force detaching any policies the role has before destroying it | bool | true | no |
| permissions_boundary_arn | ARN of the policy that is used to set the permissions boundary for the role | string | null | no |
| trusted_role_services | AWS services that can assume the role | list(string) | [] | no |
| trusted_role_arns | ARNs of AWS entities who can assume the role | list(string) | [] | no |
| trusted_role_actions | Actions of STS that are allowed for the trusted entities | list(string) | ["sts:AssumeRole"] | no |
| mfa_required | Whether MFA should be required for assuming the role | bool | false | no |
| policies | Map of policy names to policy documents | map(string) | {} | no |
| managed_policy_arns | List of AWS managed policy ARNs to attach to the IAM role | list(string) | [] | no |
| create_instance_profile | Whether to create an instance profile | bool | false | no |
| instance_profile_name | Name of the instance profile. If not provided, the role name will be used with '-profile' suffix | string | null | no |
| federated_principal | Federated principal for web identity federation (e.g., cognito-identity.amazonaws.com) | string | null | no |
| federated_conditions | Conditions for federated principal trust policy | any | null | no |
| tags | Tags to apply to all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| role_id | The ID of the IAM role |
| role_arn | The ARN of the IAM role |
| role_name | The name of the IAM role |
| role_path | The path of the IAM role |
| role_unique_id | The unique ID of the IAM role |
| policy_ids | List of IDs of the IAM policies |
| policy_arns | List of ARNs of the IAM policies |
| policy_names | List of names of the IAM policies |
| instance_profile_id | The ID of the IAM instance profile |
| instance_profile_arn | The ARN of the IAM instance profile |
| instance_profile_name | The name of the IAM instance profile |
| instance_profile_path | The path of the IAM instance profile |

## Prerequisites

- AWS account and credentials configured
- Terraform 1.3.2 or later
- AWS provider 5.83 or later

## Notes

- For production environments, it's recommended to enforce MFA for role assumption
- Use the principle of least privilege when creating IAM policies
- Instance profiles are only needed for EC2 instances
- This module follows the separation of concerns principle by focusing only on IAM resources
