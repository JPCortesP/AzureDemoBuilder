# AVD Simple and Quick - Bicep

This folder contains the low-friction Azure-native PoC deployment for Azure Virtual Desktop.

It is intentionally opinionated:

- Multi-session pooled host pool only
- Azure Entra ID login enabled on session hosts
- No Bastion
- No hybrid join
- Minimal customer inputs
- Single resource group by default for fast teardown
- Optional FSLogix storage
- Optional Log Analytics workspace

This is for fast customer validation, not production design.

## What This Deploys

- Default mode: `[prefix]-AVD`
- Optional split mode: `[prefix]-AVD.ControlPlane`, `[prefix]-AVD.Compute`, and `[prefix]-AVD.Profiles` when FSLogix is enabled
- AVD host pool, desktop app group, and workspace
- VNet, subnet, NSG, NICs, and Windows session host VMs
- Azure Entra ID login VM extension
- Optional Azure Files share for FSLogix

## Resource Group Mode

The template supports two modes:

- `singleResourceGroupDeployment = true`: default PoC mode. Everything lands in one resource group for fast cleanup.
- `singleResourceGroupDeployment = false`: split mode. Control plane, compute, and optional profiles use separate resource groups.

For a disposable PoC, the default single-resource-group mode is usually the better choice.

## What It Does Not Automate Yet

Version 1 does **not** auto-register the session hosts into the AVD host pool. That step is intentionally left out of the initial Bicep deployment because it depends on host pool registration token timing and in-guest agent installation.

For this repo, that is the right tradeoff for a stable first cut:

- low-tech customers can still launch the base environment with very few fields
- the architecture stays aligned with the Terraform version
- the fragile part stays outside the initial template until we automate it cleanly

## Parameters Customers Need

The only fields a customer usually needs to touch in [main.parameters.json](c:\code\AzureDemoBuilder\Bicep\AVD%20Simple%20and%20Quick\main.parameters.json) are:

- `location`
- `resourceGroupPrefix`
- `singleResourceGroupDeployment`
- `sessionHostCount`
- `sessionHostVmSize`
- `adminUsername`
- `adminPassword`
- `fslogixEnabled`

## Deploy With Azure CLI

From this folder:

```bash
az login
az account set --subscription <subscription-id>
az deployment sub create \
  --name avd-simple-and-quick \
  --location eastus \
  --template-file main.bicep \
  --parameters @main.parameters.json
```

## Deploy Through Azure Portal

For a portal-driven flow, compile [main.bicep](c:\code\AzureDemoBuilder\Bicep\AVD%20Simple%20and%20Quick\main.bicep) to ARM JSON and then use Azure custom deployment.

```bash
az bicep build --file main.bicep
```

That produces `main.json`, which can then be used for a future `Deploy to Azure` button.

## Recommended Operator Flow

1. Customer updates the few required parameters.
2. Customer runs the deployment or launches it from a future portal button.
3. You validate the created resource groups and AVD control plane.
4. You complete host registration as a guided post-deployment step.
5. You hand off the Terraform version when the customer wants the reusable engineering artifact.

## Relationship To Terraform

This Bicep folder is the low-tech lane.

The Terraform folder at [Terraform/AVD Simple and Quick](c:\code\AzureDemoBuilder\Terraform\AVD%20Simple%20and%20Quick) remains the richer handoff artifact for customers who want fork-and-run infrastructure code.