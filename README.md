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
- **Kubecost**: Cost monitoring and optimization with AWS CUR integration

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

## Networking Options

### VPC & Networking

The module assumes the account alread has an existing VPC to provision the cluster within. We need the VPC ID and the subnet IDs for the private subnets where the cluster should be located.

```hcl
# Use existing VPC
vpc_id = "vpc-1234567890"
private_subnet_ids = ["subnet-1234567890", "subnet-0987654321"]
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

## Kubecost Cost Monitoring

Kubecost provides comprehensive cost monitoring and optimization for Kubernetes clusters with advanced AWS integration capabilities.

### Overview

Kubecost offers three main deployment modes:

1. **Standalone**: Single cluster cost monitoring
2. **Federated Storage**: Multi-cluster aggregation for centralized monitoring
3. **Cloud Costs**: Integration with AWS Cost and Usage Reports (CUR) via Athena

### Prerequisites

Before setting up Kubecost, ensure you have:

- An active AWS account with appropriate permissions
- S3 buckets for data storage and Athena query results
- AWS Cost and Usage Report (CUR) configured (for cloud costs feature)
- Amazon Athena setup with Glue database and table (for cloud costs feature)

### AWS CUR Setup

To enable cloud costs analysis, you need to set up AWS Cost and Usage Reports:

1. **Create CUR in AWS Billing Console**:
   - Navigate to AWS Billing Dashboard
   - Create a new Cost and Usage Report with daily granularity
   - Enable Resource IDs and Athena integration
   - Specify an S3 bucket for CUR data storage

2. **Set up Athena Integration**:
   - Use the AWS-provided CloudFormation template to create Athena resources
   - Create an S3 bucket for Athena query results
   - Configure Athena workgroup and database

### IAM Permissions

The module automatically provisions the necessary IAM roles and policies:

- **S3 Access**: Read/write access to federated and CUR buckets
- **Athena Operations**: Query execution, monitoring, and result retrieval
- **Glue Metadata**: Database and table schema access for CUR data

Cost monitoring and optimization for Kubernetes clusters with AWS integration.

#### Standalone Kubecost

Basic cost monitoring for a single cluster.

```hcl
kubecosts = {
  enabled = true
}
```

#### Federated Storage (Multi-Cluster Aggregation)

Aggregate cost data from multiple clusters into a primary cluster for centralized monitoring.

```hcl
# Primary cluster (aggregates data from all clusters)
kubecosts = {
  enabled = true
  federated_storage = {
    federated_bucket_arn = "arn:aws:s3:::kubecost-federated-bucket"
    create_bucket = true
    allowed_principals = [
      "ACCOUNT_ID"
    ]
  }
}

# Secondary clusters (send data to primary)
kubecosts_agent = {
  enabled = true
  federated_bucket_name = "arn:aws:s3:::kubecost-federated-bucket"
}
```

#### Cloud Costs via AWS CUR

Integrate with AWS Cost and Usage Reports (CUR) via Amazon Athena for comprehensive cloud cost analysis.

```hcl
kubecosts = {
  enabled = true
  fedarated_storage = {
    federated_bucket_arn = "my-kubecost-bucket"
  }
  
  # Cloud costs integration with AWS CUR via Athena
  cloud_costs = {
    enable = true
    cur_bucket_name = "my-cur-bucket"
    athena_bucket_arn = "arn:s3:aws:::my-athena-results-bucket"
    athena_database_name = "cost_and_usage_data"
    athena_table_name = "cur_table"
  }
}
```

### Verification

After deployment, verify Kubecost is working correctly:

1. **Access the Dashboard**:

   ```bash
   kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
   ```

2. **Check Cloud Integration**:
   - Navigate to Settings → Cloud Cost Settings
   - Verify AWS integration is active
   - Check for any error messages

3. **Monitor Logs**:

   ```bash
   kubectl logs -n kubecost deployment/kubecost-cost-analyzer
   ```

### Additional Resources

- [Kubecost Documentation](https://docs.kubecost.com/)
- [AWS Cloud Billing Integration](https://docs.kubecost.com/cloud-integration/aws-cloud-integration)
- [Multi-Cluster Setup](https://docs.kubecost.com/install-and-configure/install/multi-cluster)
- [AWS CUR Setup Guide](https://docs.aws.amazon.com/cur/latest/userguide/)
- [Athena Integration](https://docs.aws.amazon.com/athena/latest/ug/)

## Examples

See the [examples](./examples/) directory for complete usage examples:

- [Basic EKS Cluster](./examples/basic/) - Simple EKS cluster setup
- [Platform Services](./examples/platform/) - EKS with integrated platform services
- [Custom Networking](./examples/networking/) - EKS with custom VPC and transit gateway
- [Pod Identity](./examples/pod-identity/) - EKS with custom pod identities
- [Kubecost Cost Monitoring](./examples/kubecost/) - EKS with Kubecost cost monitoring and AWS integration

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
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs, if you want to use existing subnets | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the EKS cluster will be created | `string` | n/a | yes |
| <a name="input_access_entries"></a> [access\_entries](#input\_access\_entries) | Map of access entries to add to the cluster. This is required if you use a different IAM Role for Terraform Plan actions. | <pre>map(object({<br/>    ## The list of kubernetes groups to associate the principal with<br/>    kubernetes_groups = optional(list(string), [])<br/>    ## The list of kubernetes users to associate the principal with<br/>    principal_arn = string<br/>    ## The list of kubernetes users to associate the principal with<br/>    policy_associations = optional(map(object({<br/>      ## The policy arn to associate with the principal<br/>      policy_arn = string<br/>      ## The access scope for the policy i.e. cluster or namespace<br/>      access_scope = object({<br/>        ## The namespaces to apply the policy to<br/>        namespaces = optional(list(string), [])<br/>        ## The type of access scope i.e. cluster or namespace<br/>        type = optional(string, "cluster")<br/>      })<br/>    })))<br/>  }))</pre> | `null` | no |
| <a name="input_addons"></a> [addons](#input\_addons) | Map of EKS addons to enable | <pre>map(object({<br/>    ## The name of the EKS addon<br/>    name = optional(string)<br/>    ## Indicates if we should deploy the EKS addon before the compute nodes<br/>    before_compute = optional(bool, false)<br/>    ## Indicates if we should use the most recent version of the EKS addon<br/>    most_recent = optional(bool, true)<br/>    ## The version of the EKS addon<br/>    addon_version = optional(string)<br/>    ## The configuration values for the EKS addon<br/>    configuration_values = optional(string)<br/>    ## The pod identity association for the EKS addon<br/>    pod_identity_association = optional(list(object({<br/>      ## The role ARN for the EKS addon pod identity association<br/>      role_arn = string<br/>      ## The service account for the EKS addon<br/>      service_account = string<br/>    })))<br/>    ## Indicates if we should preserve the EKS addon<br/>    preserve = optional(bool, true)<br/>    ## The resolve conflicts on create for the EKS addon<br/>    resolve_conflicts_on_create = optional(string, "OVERWRITE")<br/>    ## The resolve conflicts on update for the EKS addon<br/>    resolve_conflicts_on_update = optional(string, "OVERWRITE")<br/>    ## The service account role ARN for the EKS addon<br/>    service_account_role_arn = optional(string, null)<br/>    ## The timeouts for the EKS addon<br/>    timeouts = optional(object({<br/>      ## The timeout for the EKS addon create<br/>      create = optional(string, "10m")<br/>      ## The timeout for the EKS addon update<br/>      update = optional(string, "10m")<br/>      ## The timeout for the EKS addon delete<br/>      delete = optional(string, "10m")<br/>    }), {})<br/>    ## The tags for the EKS addon<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `null` | no |
| <a name="input_argocd"></a> [argocd](#input\_argocd) | The ArgoCD configuration | <pre>object({<br/>    ## Indicates if we should enable the ArgoCD platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the ArgoCD platform to<br/>    namespace = optional(string, "argocd")<br/>    ## The service account to deploy the ArgoCD platform to<br/>    service_account = optional(string, "argocd")<br/>  })</pre> | `{}` | no |
| <a name="input_aws_ack_iam"></a> [aws\_ack\_iam](#input\_aws\_ack\_iam) | The AWS ACK IAM configuration | <pre>object({<br/>    ## Indicates if we should enable the AWS ACK IAM platform<br/>    enable = optional(bool, true)<br/>    ## The namespace to deploy the AWS ACK IAM platform to<br/>    namespace = optional(string, "ack-system")<br/>    ## The service account to deploy the AWS ACK IAM platform to<br/>    service_account = optional(string, "ack-iam-controller")<br/>    ## Managed policies to attach to the AWS ACK IAM platform<br/>    managed_policy_arns = optional(map(string), {<br/>      "admin" = "arn:aws:iam::aws:policy/IAMFullAccess"<br/>    })<br/>  })</pre> | `{}` | no |
| <a name="input_aws_eks_ack"></a> [aws\_eks\_ack](#input\_aws\_eks\_ack) | The AWS EKS ACK Controller configuration | <pre>object({<br/>    ## Indicates if we should enable the AWS EKS ACK Controller platform<br/>    enable = optional(bool, true)<br/>    ## The namespace to deploy the AWS EKS ACK Controller platform to<br/>    namespace = optional(string, "ack-system")<br/>    ## The service account to deploy the AWS EKS ACK Controller platform to<br/>    service_account = optional(string, "ack-eks-controller")<br/>    ## Managed policies to attach to the AWS EKS ACK Controller platform<br/>    managed_policy_arns = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_aws_prometheus"></a> [aws\_prometheus](#input\_aws\_prometheus) | The AWS Prometheus configuration | <pre>object({<br/>    ## Indicates if we should enable the managed Prometheus<br/>    enable = optional(bool, false)<br/>    ## Collection of workspaces to provide permissions to i.e. arn:aws:prometheus:*:*:workspace/*<br/>    workspaces = optional(list(string), ["arn:aws:prometheus:*:*:workspace/*"])<br/>    ## The service account to deploy the AWS Prometheus to<br/>    service_account = optional(string, "prometheus")<br/>    ## The namespace to deploy the AWS Prometheus to<br/>    namespace = optional(string, "prometheus")<br/>  })</pre> | `{}` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | The cert-manager configuration | <pre>object({<br/>    ## Indicates if we should enable the cert-manager platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the cert-manager platform to<br/>    namespace = optional(string, "cert-manager")<br/>    ## The service account to deploy the cert-manager platform to<br/>    service_account = optional(string, "cert-manager")<br/>    ## Route53 zone id to use for the cert-manager platform<br/>    hosted_zone_arns = optional(list(string), ["arn:aws:route53:::hostedzone/*"])<br/>  })</pre> | `{}` | no |
| <a name="input_cloudwatch_observability"></a> [cloudwatch\_observability](#input\_cloudwatch\_observability) | The CloudWatch Observability configuration | <pre>object({<br/>    ## Indicates if we should enable the CloudWatch Observability platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the CloudWatch Observability platform to<br/>    namespace = optional(string, "cloudwatch-observability")<br/>    ## The service account to deploy the CloudWatch Observability platform to<br/>    service_account = optional(string, "cloudwatch-observability")<br/>  })</pre> | `{}` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | List of log types to enable for the EKS cluster. | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Whether to create a KMS key for the EKS cluster. | `bool` | `true` | no |
| <a name="input_ebs_csi_driver"></a> [ebs\_csi\_driver](#input\_ebs\_csi\_driver) | The EBS CSI driver configuration | <pre>object({<br/>    ## Indicates if we should enable the EBS CSI driver<br/>    enable = optional(bool, false)<br/>    ## The KMS key ARNs to allow the EBS CSI driver to manage encrypted volumes<br/>    kms_key_arns = optional(list(string), [])<br/>    ## The version of the EBS CSI driver<br/>    version = optional(string, "v1.51.0-eksbuild.1")<br/>    ## The service account to deploy the EBS CSI driver to<br/>    service_account = optional(string, "ebs-csi-controller-sa")<br/>    ## The namespace to deploy the EBS CSI driver to<br/>    namespace = optional(string, "kube-system")<br/>  })</pre> | `{}` | no |
| <a name="input_efs_csi_driver"></a> [efs\_csi\_driver](#input\_efs\_csi\_driver) | The EFS CSI driver configuration | <pre>object({<br/>    ## Indicates if we should enable the EFS CSI driver<br/>    enable = optional(bool, false)<br/>    ## The version of the EFS CSI driver<br/>    version = optional(string, "v1.6.0-eksbuild.1")<br/>    ## The service account to deploy the EFS CSI driver to<br/>    service_account = optional(string, "efs-csi-controller-sa")<br/>    ## The namespace to deploy the EFS CSI driver to<br/>    namespace = optional(string, "kube-system")<br/>  })</pre> | `{}` | no |
| <a name="input_enable_cluster_creator_admin_permissions"></a> [enable\_cluster\_creator\_admin\_permissions](#input\_enable\_cluster\_creator\_admin\_permissions) | Whether to enable cluster creator admin permissions (else create access entries for the cluster creator) | `bool` | `false` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Whether to enable IRSA for the EKS cluster. | `bool` | `true` | no |
| <a name="input_enable_private_access"></a> [enable\_private\_access](#input\_enable\_private\_access) | Whether to enable private access to the EKS API server endpoint. | `bool` | `true` | no |
| <a name="input_enable_public_access"></a> [enable\_public\_access](#input\_enable\_public\_access) | Whether to enable public access to the EKS API server endpoint. | `bool` | `false` | no |
| <a name="input_endpoint_public_access_cidrs"></a> [endpoint\_public\_access\_cidrs](#input\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS API server endpoint. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | The External DNS configuration | <pre>object({<br/>    ## Indicates if we should enable the External DNS platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the External DNS platform to<br/>    namespace = optional(string, "external-dns")<br/>    ## The service account to deploy the External DNS platform to<br/>    service_account = optional(string, "external-dns")<br/>    ## The route53 zone ARNs to attach to the External DNS platform<br/>    hosted_zone_arns = optional(list(string), ["arn:aws:route53:::hostedzone/*"])<br/>  })</pre> | `{}` | no |
| <a name="input_external_secrets"></a> [external\_secrets](#input\_external\_secrets) | The External Secrets configuration | <pre>object({<br/>    ## Indicates if we should enable the External Secrets platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the External Secrets platform to<br/>    namespace = optional(string, "external-secrets")<br/>    ## The service account to deploy the External Secrets platform to<br/>    service_account = optional(string, "external-secrets")<br/>    ## The secrets manager ARNs to attach to the External Secrets platform<br/>    secrets_manager_arns = optional(list(string), ["arn:aws:secretsmanager:::secret/*"])<br/>    ## The SSM parameter ARNs to attach to the External Secrets platform<br/>    ssm_parameter_arns = optional(list(string), ["arn:aws:ssm:::parameter/eks/*"])<br/>  })</pre> | `{}` | no |
| <a name="input_hub_account_id"></a> [hub\_account\_id](#input\_hub\_account\_id) | The AWS account ID of the hub account | `string` | `null` | no |
| <a name="input_hub_account_role"></a> [hub\_account\_role](#input\_hub\_account\_role) | Indicates we should create a cross account role for the hub to assume | `string` | `"argocd-pod-identity-hub"` | no |
| <a name="input_hub_account_roles_prefix"></a> [hub\_account\_roles\_prefix](#input\_hub\_account\_roles\_prefix) | The prefix of the roles we are permitted to assume via the argocd pod identity | `string` | `"argocd-cross-account-*"` | no |
| <a name="input_kms_key_administrators"></a> [kms\_key\_administrators](#input\_kms\_key\_administrators) | A list of IAM ARNs for EKS key administrators. If no value is provided, the current caller identity is used to ensure at least one key admin is available. | `list(string)` | `[]` | no |
| <a name="input_kms_key_service_users"></a> [kms\_key\_service\_users](#input\_kms\_key\_service\_users) | A list of IAM ARNs for EKS key service users. | `list(string)` | `[]` | no |
| <a name="input_kms_key_users"></a> [kms\_key\_users](#input\_kms\_key\_users) | A list of IAM ARNs for EKS key users. | `list(string)` | `[]` | no |
| <a name="input_kubecosts"></a> [kubecosts](#input\_kubecosts) | The Kubecost configuration | <pre>object({<br/>    ## Indicates if we should enable the Kubecost platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the Kubecost platform to<br/>    namespace = optional(string, "kubecost")<br/>    ## The service account to deploy the Kubecost platform to<br/>    service_account = optional(string, "kubecost")<br/>    ## Fedarate storage configuration<br/>    federated_storage = optional(object({<br/>      ## Indicates if we should create the federated bucket<br/>      create_bucket = optional(bool, false)<br/>      ## KMS key ARN to use for the federated bucket<br/>      kms_key_arn = optional(string, null)<br/>      ## The ARN of the federated bucket to use for the Kubecost platform<br/>      federated_bucket_arn = optional(string, null)<br/>      ## List of principals to allowed to write to the federated bucket<br/>      allowed_principals = optional(list(string), [])<br/>    }), {})<br/>    ## Cloud Costs feature <br/>    cloud_costs = optional(object({<br/>      ## Indicates if we should enable cloud costs via Athena<br/>      enable = optional(bool, false)<br/>      ## The ARN of the S3 bucket for Cost and Usage Report (CUR) data<br/>      cur_bucket_arn = optional(string, null)<br/>      ## The ARN of the S3 bucket for Athena query results<br/>      athena_bucket_arn = optional(string, null)<br/>      ## The name of the Athena database for CUR data<br/>      athena_database_name = optional(string, null)<br/>      ## The ARN of the Athena table for CUR data<br/>      athena_table_name = optional(string, null)<br/>    }), {})<br/>  })</pre> | `null` | no |
| <a name="input_kubecosts_agent"></a> [kubecosts\_agent](#input\_kubecosts\_agent) | The Kubecost Agent configuration | <pre>object({<br/>    ## Indicates if we should enable the Kubecost Agent platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the Kubecost Agent platform to<br/>    namespace = optional(string, "kubecost")<br/>    ## The service account to deploy the Kubecost Agent platform to<br/>    service_account = optional(string, "kubecost-agent")<br/>    ## The ARN of the federated bucket to use for the Kubecost Agent platform<br/>    federated_bucket_arn = string<br/>  })</pre> | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the EKS cluster | `string` | `"1.34"` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Collection of nodepools to create via auto-mote karpenter | `list(string)` | <pre>[<br/>  "system"<br/>]</pre> | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source. | `any` | `{}` | no |
| <a name="input_pod_identity"></a> [pod\_identity](#input\_pod\_identity) | The pod identity configuration | <pre>map(object({<br/>    ## Indicates if we should enable the pod identity<br/>    enabled = optional(bool, true)<br/>    ## The namespace to deploy the pod identity to<br/>    description = optional(string, null)<br/>    ## The service account to deploy the pod identity to<br/>    service_account = optional(string, null)<br/>    ## The managed policy ARNs to attach to the pod identity<br/>    managed_policy_arns = optional(map(string), {})<br/>    ## The permissions boundary ARN to use for the pod identity<br/>    permissions_boundary_arn = optional(string, null)<br/>    ## The namespace to deploy the pod identity to<br/>    namespace = optional(string, null)<br/>    ## The name of the pod identity role<br/>    name = optional(string, null)<br/>    ## Additional policy statements to attach to the pod identity role<br/>    policy_statements = optional(list(object({<br/>      ## The statement ID<br/>      sid = optional(string, null)<br/>      ## The actions to allow<br/>      actions = optional(list(string), [])<br/>      ## The resources to allow<br/>      resources = optional(list(string), [])<br/>      ## The effect to allow<br/>      effect = optional(string, null)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_registries"></a> [registries](#input\_registries) | Provision pull-through cache for registries | <pre>map(object({<br/>    ## The name of the registry<br/>    name = string<br/>    ## The URL of the registry<br/>    url = string<br/>    ## Optional credentials arn to use for the registry<br/>    credentials_arn = optional(string, null)<br/>    ## Optional credentials to use for the registry<br/>    credentials = optional(object({<br/>      ## Name of the secret to provision in aws secrets manager<br/>      secret_name = optional(string, null)<br/>      ## The username to use for the registry<br/>      username = string<br/>      ## The password to use for the registry<br/>      password = string<br/>    }), null)<br/>  }))</pre> | `{}` | no |
| <a name="input_security_group_additional_rules"></a> [security\_group\_additional\_rules](#input\_security\_group\_additional\_rules) | List of additional security group rules to add to the cluster security group created | `any` | `{}` | no |
| <a name="input_terranetes"></a> [terranetes](#input\_terranetes) | The Terranetes platform configuration | <pre>object({<br/>    ## Indicates if we should enable the Terranetes platform<br/>    enable = optional(bool, false)<br/>    ## The namespace to deploy the Terranetes platform to<br/>    namespace = optional(string, "terraform-system")<br/>    ## The service account to deploy the Terranetes platform to<br/>    service_account = optional(string, "terranetes-executor")<br/>    ## The permissions boundary ARN to use for the Terranetes platform<br/>    permissions_boundary_arn = optional(string, null)<br/>    ## Managed policies to attach to the Terranetes platform<br/>    managed_policy_arns = optional(map(string), {<br/>      "AdministratorAccess" = "arn:aws:iam::aws:policy/AdministratorAccess"<br/>    })<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The AWS account ID. |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN of the EKS cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | The base64 encoded certificate data for the EKS cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The endpoint for the EKS Kubernetes API |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The name of the EKS cluster. |
| <a name="output_cluster_oidc_provider_arn"></a> [cluster\_oidc\_provider\_arn](#output\_cluster\_oidc\_provider\_arn) | The ARN of the OIDC provider for the EKS cluster |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | The cross account arn when we are using a hub |
| <a name="output_ebs_csi_driver_pod_identity_arn"></a> [ebs\_csi\_driver\_pod\_identity\_arn](#output\_ebs\_csi\_driver\_pod\_identity\_arn) | The ARN of the EBS CSI driver pod identity |
| <a name="output_efs_csi_driver_pod_identity_arn"></a> [efs\_csi\_driver\_pod\_identity\_arn](#output\_efs\_csi\_driver\_pod\_identity\_arn) | The ARN of the EFS CSI driver pod identity |
| <a name="output_region"></a> [region](#output\_region) | The AWS region in which the cluster is provisioned |
<!-- END_TF_DOCS -->