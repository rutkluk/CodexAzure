# Secure Azure Data Factory Baseline (Policy Initiative + Assignment)

## Overview

This Terraform configuration creates and assigns a security baseline for Azure Data Factory (ADF).

It enforces all of the following:

1. **Managed Virtual Network is required**  
   - All Data Factories must have Managed Virtual Network (Managed VNet) enabled.

2. **Public network access is disabled**  
   - ADF cannot communicate over public endpoints. This pushes all traffic toward Private Link / Managed Private Endpoints.

3. **Customer-Managed Keys (CMK) required**  
   - ADF must use a key from Azure Key Vault (not Microsoft-managed keys) for encryption at rest.

4. **Region restriction**  
   - ADF can only be deployed to approved regions  
     (defaults: `westeurope`, `northeurope`).

These requirements are bundled into one Azure Policy Initiative (“policy set”) and then assigned at subscription scope.

---

## Repo Structure / Files

```text
.
├─ main.tf                 # Initiative definition + assignment
├─ variables.tf            # Input variables (regions, subscription, etc.)
├─ terraform.tfvars        # Your environment values (subscription ID, etc.)
├─ outputs.tf              # Helpful outputs after apply
└─ README.md               # This file
```

---

## Prerequisites

- Terraform >= 1.5.0  
- Azurerm provider ~> 4.x  
- You have `Owner` or `Resource Policy Contributor` on the target scope (subscription, management group, etc.).  
- You know which subscription you are targeting.

> Note: Policy creation at subscription scope typically requires `Microsoft.Authorization/policySetDefinitions/write` and `policyAssignments/write`.

---

## Variables

Key variables defined in `variables.tf`:

- `subscription_id`  
  The subscription where the policy initiative will be assigned.

- `allowed_regions`  
  List of regions where ADF is allowed. Defaults:
  ```hcl
  ["westeurope", "northeurope"]
  ```

- `enforcement_mode`  
  - `"Default"` = enforce (deny noncompliant deployments)
  - `"DoNotEnforce"` = audit-only

- `policy_initiative_name`, `policy_assignment_name`, etc.  
  Naming/taxonomy controls (mainly for consistency in Azure Policy UI).

---

## Example `terraform.tfvars`

```hcl
subscription_id       = "00000000-0000-0000-0000-000000000000"
allowed_regions       = ["westeurope", "northeurope"]
enforcement_mode      = "Default"
policy_initiative_name = "Secure-ADF-Baseline"
policy_assignment_name = "enforce-secure-adf"
policy_category       = "Data Factory"
policy_version        = "1.0.0"
```

> Replace `00000000-0000-0000-0000-000000000000` with your subscription ID.

---

## How to Deploy

### 1. Initialize Terraform

```bash
terraform init
```

---

### 2. Review the plan

```bash
terraform plan
```

You should see:
- `azurerm_policy_set_definition.secure_adf_baseline` will be created  
- `azurerm_policy_assignment.secure_adf_assignment` will be created  
- Assignment scope matches your subscription

---

### 3. Apply

```bash
terraform apply
```

Confirm when prompted.

Outputs after apply will include:
- Policy Set Definition ID
- Policy Assignment ID
- Scope
- Allowed regions

You can paste those into audit/compliance evidence.

---

## How to Verify in Azure Portal

### A. Verify the Initiative

1. Azure Portal → **Policy** → **Definitions**  
2. Filter:
   - Type: `Initiative`
   - Category: whatever you set in `policy_category` (default: `Data Factory`)
3. You should see something like `Secure Azure Data Factory Baseline`.

Open it. You should see 4 included policies:
- Require Managed Virtual Network  
- Disable Public Network Access  
- Require CMK  
- Allowed Locations

---

### B. Verify Assignment

1. Azure Portal → **Policy** → **Assignments**  
2. Scope: your subscription  
3. Look for `Secure Azure Data Factory Baseline` / `enforce-secure-adf`

Check:
- Scope matches the subscription you expect  
- Parameters show only allowed regions  
- `enforcement_mode` is what you set (`Default` for deny, `DoNotEnforce` for audit-only)

---

### C. Compliance View

Portal → **Policy** → **Compliance** → pick initiative.

You’ll see which ADF resources are:
- Compliant ✅
- Non-compliant ❌ (e.g. wrong region, public network enabled, no CMK, etc.)

If `enforcement_mode = "DoNotEnforce"`, you'll get visibility without actually blocking deployments yet.

---

## Behavior You Should Expect After Enforcement

With enforcement enabled (`Default`):

- Creating an ADF in `uksouth` → denied  
- Creating ADF with `publicNetworkAccess = Enabled` → denied  
- Creating ADF without Managed VNet → denied  
- Creating ADF without CMK → denied or audited (depending on the CMK policy effect you referenced)

This prevents accidental insecure deployments in production.

---

## Extending the Baseline

You can extend this baseline by adding more `policy_definitions` to `main.tf`, for example:

- Require standard tags (`owner`, `env`, `cost_center`)  
- Restrict ADF to certain naming conventions  
- Restrict use of self-hosted integration runtimes  
- Require Key Vault used for CMK to be in the same region as the factory

Those can all live in the same initiative so you only assign one thing.

---

## Notes

- This baseline does NOT automatically create Managed Private Endpoints.  
  It just **forces ADF to be private-only and region-limited**.

- Security / platform / compliance teams can use the `outputs.tf` results and screenshots of the Portal Compliance blade as audit evidence.

---
