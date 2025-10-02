<!-- markdownlint-disable -->
<p align="right"> <a href="https://registry.terraform.io/modules/appvia/eks/aws/latest"><img src="https://img.shields.io/static/v1?label=APPVIA&message=Terraform%20Registry&color=191970&style=for-the-badge" alt="Terraform Registry"/></a></a> <a href="https://github.com/appvia/terraform-aws-eks/releases/latest"><img src="https://img.shields.io/github/release/appvia/terraform-aws-eks.svg?style=for-the-badge&color=006400" alt="Latest Release"/></a> <a href="https://appvia-community.slack.com/join/shared_invite/zt-1s7i7xy85-T155drryqU56emm09ojMVA#/shared-invite/email"><img src="https://img.shields.io/badge/Slack-Join%20Community-purple?style=for-the-badge&logo=slack" alt="Slack Community"/></a> <a href="https://github.com/appvia/terraform-aws-eks/graphs/contributors"><img src="https://img.shields.io/github/contributors/appvia/terraform-aws-eks.svg?style=for-the-badge&color=FF8C00" alt="Contributors"/></a>

<!-- markdownlint-restore -->
<!--
  ***** CAUTION: DO NOT EDIT ABOVE THIS LINE ******
-->

![Github Actions](https://github.com/appvia/terraform-aws-eks/actions/workflows/terraform.yml/badge.svg)

# Terraform AWS EKS Module

A comprehensive Terraform module for provisioning Amazon Elastic Kubernetes Service (EKS) clusters with integrated platform services, pod identity management, and networking capabilities.

## Description

This module provides a production-ready EKS cluster with integrated platform services and best practices. It includes:

- **EKS Cluster Management**: Full EKS cluster provisioning with configurable versions and logging
- **Platform Integrations**: Built-in support for ArgoCD, cert-manager, External DNS, External Secrets, and more
- **Pod Identity Management**: AWS Pod Identity for secure workload-to-AWS service authentication
- **Networking**: Optional VPC creation with transit gateway support
- **Security**: Configurable security groups, access entries, and KMS encryption
- **Cross-Account Support**: Hub-spoke architecture for multi-account deployments

## Key Features

### 🚀 **EKS Cluster Management**

- Kubernetes version 1.32+ support
- Configurable cluster logging (API, audit, authenticator, controller manager, scheduler)
- Public/private endpoint access control
- KMS encryption for cluster secrets
- Auto-scaling with Karpenter integration

### 🔐 **Security & Access Control**

- AWS Pod Identity for secure workload authentication
- Configurable access entries for cluster access
- Security group management with customizable rules
- Cross-account role support for hub-spoke architectures

### 🌐 **Platform Integrations**

- **ArgoCD**: GitOps deployment platform
- **cert-manager**: Automated certificate management
- **External DNS**: Route53 integration for service discovery
- **External Secrets**: AWS Secrets Manager and SSM Parameter Store integration
- **Terranetes**: Terraform-as-a-Service platform
- **AWS ACK IAM**: AWS Controllers for Kubernetes
- **CloudWatch Observability**: Monitoring and logging

### 🏗️ **Networking**

- Optional VPC creation with configurable CIDR blocks
- Transit Gateway integration for multi-VPC connectivity
- NAT Gateway support (single AZ or all AZs)
- Subnet tagging for Kubernetes service discovery

## Usage

### Basic EKS Cluster

```hcl
module "eks" {
  source = "appvia/eks/aws"
  version = "1.0.0"

  cluster_name = "my-eks-cluster"
  tags = {
    Environment = "Production"
    Product     = "EKS"
    Owner       = "Engineering"
  }
}
```

### EKS Cluster with Platform Services

```hcl
module "eks" {
  source = "appvia/eks/aws"
  version = "1.0.0"

  cluster_name = "production-eks"
  tags = {
    Environment = "Production"
    Product     = "EKS"
    Owner       = "Engineering"
  }

  # Enable platform services
  argocd = {
    enabled = true
    namespace = "argocd"
    service_account = "argocd"
  }

  cert_manager = {
    enabled = true
    namespace = "cert-manager"
    service_account = "cert-manager"
    route53_zone_arns = ["arn:aws:route53:::hostedzone/Z1234567890"]
  }

  external_dns = {
    enabled = true
    namespace = "external-dns"
    service_account = "external-dns"
    route53_zone_arns = ["arn:aws:route53:::hostedzone/Z1234567890"]
  }

  external_secrets = {
    enabled = true
    namespace = "external-secrets"
    service_account = "external-secrets"
    secrets_manager_arns = ["arn:aws:secretsmanager:*:*"]
    ssm_parameter_arns = ["arn:aws:ssm:*:*:parameter/eks/*"]
  }
}
```

### EKS Cluster with Custom Networking

```hcl
module "eks" {
  source = "appvia/eks/aws"
  version = "1.0.0"

  cluster_name = "custom-network-eks"
  tags = {
    Environment = "Production"
    Product     = "EKS"
    Owner       = "Engineering"
  }

  # Custom VPC configuration
  vpc_cidr = "10.100.0.0/21"
  availability_zones = 3
  nat_gateway_mode = "all_azs"
  private_subnet_netmask = 24
  public_subnet_netmask = 24

  # Transit Gateway integration
  transit_gateway_id = "tgw-1234567890"
  transit_gateway_routes = {
    private = "10.0.0.0/8"
    database = "10.1.0.0/16"
  }
}
```

### EKS Cluster with Pod Identity

```hcl
module "eks" {
  source = "appvia/eks/aws"
  version = "1.0.0"

  cluster_name = "pod-identity-eks"
  tags = {
    Environment = "Production"
    Product     = "EKS"
    Owner       = "Engineering"
  }

  # Custom pod identities
  pod_identity = {
    my-app = {
      enabled = true
      name = "my-app-pod-identity"
      namespace = "my-app"
      service_account = "my-app-sa"
      managed_policy_arns = {
        "S3ReadOnly" = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        "DynamoDBReadWrite" = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
      }
      policy_statements = [
        {
          sid = "CustomPolicy"
          effect = "Allow"
          actions = ["s3:GetObject"]
          resources = ["arn:aws:s3:::my-bucket/*"]
        }
      ]
    }
  }
}
```

### Hub-Spoke Architecture

```hcl
module "eks" {
  source = "appvia/eks/aws"
  version = "1.0.0"

  cluster_name = "spoke-eks"
  tags = {
    Environment = "Production"
    Product     = "EKS"
    Owner       = "Engineering"
  }

  # Hub account configuration
  hub_account_id = "123456789012"
  hub_account_role = "argocd-pod-identity-hub"
  hub_account_roles_prefix = "argocd-cross-account-*"

  # Enable ArgoCD for GitOps
  argocd = {
    enabled = true
    namespace = "argocd"
    service_account = "argocd"
  }
}
```

## Platform Services

### ArgoCD

GitOps deployment platform for Kubernetes applications.

```hcl
argocd = {
  enabled = true
  namespace = "argocd"
  service_account = "argocd"
}
```

### cert-manager

Automated certificate management for Kubernetes.

```hcl
cert_manager = {
  enabled = true
  namespace = "cert-manager"
  service_account = "cert-manager"
  route53_zone_arns = ["arn:aws:route53:::hostedzone/Z1234567890"]
}
```

### External DNS

Route53 integration for automatic DNS record management.

```hcl
external_dns = {
  enabled = true
  namespace = "external-dns"
  service_account = "external-dns"
  route53_zone_arns = ["arn:aws:route53:::hostedzone/Z1234567890"]
}
```

### External Secrets

AWS Secrets Manager and SSM Parameter Store integration.

```hcl
external_secrets = {
  enabled = true
  namespace = "external-secrets"
  service_account = "external-secrets"
  secrets_manager_arns = ["arn:aws:secretsmanager:*:*"]
  ssm_parameter_arns = ["arn:aws:ssm:*:*:parameter/eks/*"]
}
```

### Terranetes

Terraform-as-a-Service platform for infrastructure management.

```hcl
terranetes = {
  enabled = true
  namespace = "terraform-system"
  service_account = "terranetes-executor"
  managed_policy_arns = {
    "AdministratorAccess" = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}
```

### AWS ACK IAM

AWS Controllers for Kubernetes IAM management.

```hcl
aws_ack_iam = {
  enabled = true
  namespace = "ack-system"
  service_account = "ack-iam-controller"
  managed_policy_arns = {}
}
```

### CloudWatch Observability

Monitoring and logging with CloudWatch.

```hcl
cloudwatch_observability = {
  enabled = true
  namespace = "cloudwatch-observability"
  service_account = "cloudwatch-observability"
}
```

## Networking Options

### VPC Creation

The module can create a new VPC or use an existing one.

```hcl
# Create new VPC
vpc_cidr = "10.0.0.0/21"
availability_zones = 3

# Use existing VPC
vpc_id = "vpc-1234567890"
private_subnet_ids = ["subnet-1234567890", "subnet-0987654321"]
```

### Transit Gateway Integration

Connect to existing transit gateways for multi-VPC connectivity.

```hcl
transit_gateway_id = "tgw-1234567890"
transit_gateway_routes = {
  private = "10.0.0.0/8"
  database = "10.1.0.0/16"
}
```

### NAT Gateway Configuration

Configure NAT gateways for outbound internet access.

```hcl
nat_gateway_mode = "single_az"  # or "all_azs"
```

## Security Features

### Access Control

Configure cluster access using access entries.

```hcl
access_entries = {
  admin = {
    principal_arn = "arn:aws:iam::123456789012:role/AdminRole"
    policy_associations = {
      cluster_admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = {
          type = "cluster"
        }
      }
    }
  }
}
```

### Pod Identity

Secure workload-to-AWS service authentication.

```hcl
pod_identity = {
  my-workload = {
    enabled = true
    name = "my-workload-identity"
    namespace = "my-namespace"
    service_account = "my-service-account"
    managed_policy_arns = {
      "S3Access" = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    }
  }
}
```

### Security Groups

Customize security group rules for cluster and nodes.

```hcl
cluster_security_group_additional_rules = {
  custom_ingress = {
    description = "Custom ingress rule"
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    type        = "ingress"
    cidr_blocks = ["10.0.0.0/8"]
  }
}

node_security_group_additional_rules = {
  custom_egress = {
    description = "Custom egress rule"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    type        = "egress"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Examples

See the [examples](./examples/) directory for complete usage examples:

- [Basic EKS Cluster](./examples/basic/) - Simple EKS cluster setup
- [Platform Services](./examples/platform/) - EKS with integrated platform services
- [Custom Networking](./examples/networking/) - EKS with custom VPC and transit gateway
- [Pod Identity](./examples/pod-identity/) - EKS with custom pod identities

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.34 |

## Update Documentation

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:

1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (<https://terraform-docs.io/user-guide/installation/>)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the Kubenetes cluster | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_access_entries"></a> [access\_entries](#input\_access\_entries) | Map of access entries to add to the cluster. This is required if you use a different IAM Role for Terraform Plan actions. | <pre>map(object({<br/>    ## The list of kubernetes groups to associate the principal with<br/>    kubernetes_groups = optional(list(string))<br/>    ## The list of kubernetes users to associate the principal with<br/>    principal_arn = string<br/>    ## The list of kubernetes users to associate the principal with<br/>    policy_associations = optional(map(object({<br/>      ## The policy arn to associate with the principal<br/>      policy_arn = string<br/>      ## The access scope for the policy i.e. cluster or namespace<br/>      access_scope = object({<br/>        ## The namespaces to apply the policy to<br/>        namespaces = optional(list(string))<br/>        ## The type of access scope i.e. cluster or namespace<br/>        type = string<br/>      })<br/>    })))<br/>  }))</pre> | `null` | no |
| <a name="input_argocd"></a> [argocd](#input\_argocd) | The ArgoCD configuration | <pre>object({<br/>    ## Indicates if we should enable the ArgoCD platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the ArgoCD platform to<br/>    namespace = optional(string, "argocd")<br/>    ## The service account to deploy the ArgoCD platform to<br/>    service_account = optional(string, "argocd")<br/>  })</pre> | `{}` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Number of availability zones when provisioning a network | `number` | `3` | no |
| <a name="input_aws_ack_iam"></a> [aws\_ack\_iam](#input\_aws\_ack\_iam) | The AWS ACK IAM configuration | <pre>object({<br/>    ## Indicates if we should enable the AWS ACK IAM platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the AWS ACK IAM platform to<br/>    namespace = optional(string, "ack-system")<br/>    ## The service account to deploy the AWS ACK IAM platform to<br/>    service_account = optional(string, "ack-iam-controller")<br/>    ## Managed policies to attach to the AWS ACK IAM platform<br/>    managed_policy_arns = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | The cert-manager configuration | <pre>object({<br/>    ## Indicates if we should enable the cert-manager platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the cert-manager platform to<br/>    namespace = optional(string, "cert-manager")<br/>    ## The service account to deploy the cert-manager platform to<br/>    service_account = optional(string, "cert-manager")<br/>    ## Route53 zone id to use for the cert-manager platform<br/>    route53_zone_arns = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_cloudwatch_observability"></a> [cloudwatch\_observability](#input\_cloudwatch\_observability) | The CloudWatch Observability configuration | <pre>object({<br/>    ## Indicates if we should enable the CloudWatch Observability platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the CloudWatch Observability platform to<br/>    namespace = optional(string, "cloudwatch-observability")<br/>    ## The service account to deploy the CloudWatch Observability platform to<br/>    service_account = optional(string, "cloudwatch-observability")<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | List of log types to enable for the EKS cluster. | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether to enable public access to the EKS API server endpoint. | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS API server endpoint. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source. | `any` | `{}` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version for the EKS cluster | `string` | `"1.32"` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | The External DNS configuration | <pre>object({<br/>    ## Indicates if we should enable the External DNS platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the External DNS platform to<br/>    namespace = optional(string, "external-dns")<br/>    ## The service account to deploy the External DNS platform to<br/>    service_account = optional(string, "external-dns")<br/>    ## The route53 zone ARNs to attach to the External DNS platform<br/>    route53_zone_arns = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_external_secrets"></a> [external\_secrets](#input\_external\_secrets) | The External Secrets configuration | <pre>object({<br/>    ## Indicates if we should enable the External Secrets platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the External Secrets platform to<br/>    namespace = optional(string, "external-secrets")<br/>    ## The service account to deploy the External Secrets platform to<br/>    service_account = optional(string, "external-secrets")<br/>    ## The secrets manager ARNs to attach to the External Secrets platform<br/>    secrets_manager_arns = optional(list(string), ["arn:aws:secretsmanager:*:*"])<br/>    ## The SSM parameter ARNs to attach to the External Secrets platform<br/>    ssm_parameter_arns = optional(list(string), ["arn:aws:ssm:*:*:parameter/eks/*"])<br/>  })</pre> | `{}` | no |
| <a name="input_hub_account_id"></a> [hub\_account\_id](#input\_hub\_account\_id) | The AWS account ID of the hub account | `string` | `null` | no |
| <a name="input_hub_account_role"></a> [hub\_account\_role](#input\_hub\_account\_role) | Indicates we should create a cross account role for the hub to assume | `string` | `"argocd-pod-identity-hub"` | no |
| <a name="input_hub_account_roles_prefix"></a> [hub\_account\_roles\_prefix](#input\_hub\_account\_roles\_prefix) | The prefix of the roles we are permitted to assume via the argocd pod identity | `string` | `"argocd-cross-account-*"` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | A list of IAM ARNs for EKS key administrators. If no value is provided, the current caller identity is used to ensure at least one key admin is available. | `list(string)` | `[]` | no |
| <a name="input_nat_gateway_mode"></a> [nat\_gateway\_mode](#input\_nat\_gateway\_mode) | The mode to use for the NAT gateway, when enable\_gateway is true | `string` | `"single_az"` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Collection of nodepools to create via auto-mote karpenter | `list(string)` | <pre>[<br/>  "system"<br/>]</pre> | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source. | `any` | `{}` | no |
| <a name="input_pod_identity"></a> [pod\_identity](#input\_pod\_identity) | The pod identity configuration | <pre>map(object({<br/>    ## Indicates if we should enable the pod identity<br/>    enabled = optional(bool, true)<br/>    ## The namespace to deploy the pod identity to<br/>    description = optional(string, null)<br/>    ## The service account to deploy the pod identity to<br/>    service_account = optional(string, null)<br/>    ## The managed policy ARNs to attach to the pod identity<br/>    managed_policy_arns = optional(map(string), {})<br/>    ## The permissions boundary ARN to use for the pod identity<br/>    permissions_boundary_arn = optional(string, null)<br/>    ## The namespace to deploy the pod identity to<br/>    namespace = optional(string, null)<br/>    ## The name of the pod identity role<br/>    name = optional(string, null)<br/>    ## Additional policy statements to attach to the pod identity role<br/>    policy_statements = optional(list(object({<br/>      sid       = optional(string, null)<br/>      actions   = optional(list(string), [])<br/>      resources = optional(list(string), [])<br/>      effect    = optional(string, null)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs, if you want to use existing subnets | `list(string)` | `null` | no |
| <a name="input_private_subnet_netmask"></a> [private\_subnet\_netmask](#input\_private\_subnet\_netmask) | The netmask for the private subnets | `number` | `24` | no |
| <a name="input_public_subnet_netmask"></a> [public\_subnet\_netmask](#input\_public\_subnet\_netmask) | The netmask for the public subnets | `number` | `24` | no |
| <a name="input_terranetes"></a> [terranetes](#input\_terranetes) | The Terranetes platform configuration | <pre>object({<br/>    ## Indicates if we should enable the Terranetes platform<br/>    enabled = optional(bool, false)<br/>    ## The namespace to deploy the Terranetes platform to<br/>    namespace = optional(string, "terraform-system")<br/>    ## The service account to deploy the Terranetes platform to<br/>    service_account = optional(string, "terranetes-executor")<br/>    ## The permissions boundary ARN to use for the Terranetes platform<br/>    permissions_boundary_arn = optional(string, null)<br/>    ## Managed policies to attach to the Terranetes platform<br/>    managed_policy_arns = optional(map(string), {<br/>      "AdministratorAccess" = "arn:aws:iam::aws:policy/AdministratorAccess"<br/>    })<br/>  })</pre> | `{}` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | The ID of the transit gateway to use | `string` | `null` | no |
| <a name="input_transit_gateway_routes"></a> [transit\_gateway\_routes](#input\_transit\_gateway\_routes) | The routes to add to the transit gateway route table | `map(string)` | <pre>{<br/>  "private": "10.0.0.0/8"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the Wayfinder VPC. | `string` | `"10.0.0.0/21"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the EKS cluster will be created | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The AWS account ID. |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | The base64 encoded certificate data for the Wayfinder EKS cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The endpoint for the Wayfinder EKS Kubernetes API |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the Wayfinder EKS cluster. |
| <a name="output_cluster_oidc_provider_arn"></a> [cluster\_oidc\_provider\_arn](#output\_cluster\_oidc\_provider\_arn) | The ARN of the OIDC provider for the Wayfinder EKS cluster |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | The cross account arn when we are using a hub |
| <a name="output_region"></a> [region](#output\_region) | The AWS region in which the cluster is provisioned |
<!-- END_TF_DOCS -->