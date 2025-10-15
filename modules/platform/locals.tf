
locals {
  ## Normalizes tenancy path
  tenant_path = (var.tenant_path != "" && !endswith(var.tenant_path, "/")) ? format("%s/", var.tenant_path) : var.tenant_path
}

