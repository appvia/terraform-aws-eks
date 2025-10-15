<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd_repositories"></a> [argocd\_repositories](#input\_argocd\_repositories) | A collection of repository secrets to add to the argocd namespace | <pre>map(object({<br/>    ## The description of the repository<br/>    description = string<br/>    ## The secret to use for the repository<br/>    secret = optional(string, null)<br/>    ## The secret manager ARN to use for the secret<br/>    secret_manager_arn = optional(string, null)<br/>    ## An optional SSH private key for the repository<br/>    ssh_private_key = optional(string, null)<br/>    ## The URL of the repository<br/>    url = string<br/>    ## An optional username for the repository<br/>    username = optional(string, null)<br/>    ## An optional password for the repository<br/>    password = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | The public access to the cluster endpoint | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Enable the NAT gateway | `bool` | `true` | no |
| <a name="input_hub_account_id"></a> [hub\_account\_id](#input\_hub\_account\_id) | When using a hub deployment options, this is the account where argocd is running | `string` | `null` | no |
| <a name="input_nat_gateway_mode"></a> [nat\_gateway\_mode](#input\_nat\_gateway\_mode) | The NAT gateway mode | `string` | `"single_az"` | no |
| <a name="input_private_subnet_netmask"></a> [private\_subnet\_netmask](#input\_private\_subnet\_netmask) | The netmask for the private subnets | `number` | `24` | no |
| <a name="input_public_subnet_netmask"></a> [public\_subnet\_netmask](#input\_public\_subnet\_netmask) | The netmask for the public subnets | `number` | `24` | no |
| <a name="input_sso_role_name"></a> [sso\_role\_name](#input\_sso\_role\_name) | The SSO Administrator role ARN | `string` | `"AWSReservedSSO_Administrator_fbb916977087a86f"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | `"10.90.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | The certificate authority of the EKS cluster |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | The endpoint of the EKS cluster |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | The name of the EKS cluster |
<!-- END_TF_DOCS -->