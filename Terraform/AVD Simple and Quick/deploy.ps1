# Azure Virtual Desktop Terraform Demo - Quick Start Script
# This script helps validate your environment and initiate Terraform deployment

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("init", "plan", "apply", "destroy", "validate", "output", "state")]
    [string]$Action = "init"
)

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Invoke-Terraform {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Arguments,
        
        [Parameter(Mandatory=$false)]
        [switch]$CapturePath
    )
    
    if ($script:UseWSL) {
        $workingDir = (Get-Location).Path
        # Convert Windows path to WSL path (C:\path -> /mnt/c/path)
        $wslPath = $workingDir -replace '^([C-Z]):', '/mnt/$1' -replace '\\', '/'
        
        if ($CapturePath) {
            # Return the command to execute in WSL
            return "wsl -d Ubuntu bash -c 'cd $wslPath && terraform $Arguments'"
        } else {
            # Execute directly in WSL
            Invoke-Expression "wsl -d Ubuntu bash -c 'cd $wslPath && terraform $Arguments'"
        }
    } else {
        if ($CapturePath) {
            return "terraform $Arguments"
        } else {
            Invoke-Expression "terraform $Arguments"
        }
    }
}

function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check Terraform - first in Windows, then in WSL
    Write-Info "Checking Terraform installation..."
    $script:UseWSL = $false
    $terraform = Get-Command terraform -ErrorAction SilentlyContinue
    
    if ($terraform) {
        $tfVersion = terraform version | Select-Object -First 1
        Write-Success "Terraform found (Windows): $tfVersion"
    } else {
        # Try WSL
        Write-Info "Terraform not found in Windows. Checking WSL..."
        try {
            $wslCheck = wsl terraform version 2>&1 | Select-Object -First 1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Terraform found in WSL: $wslCheck"
                $script:UseWSL = $true
            } else {
                throw "Not found in WSL"
            }
        } catch {
            Write-Error "Terraform not found in Windows or WSL."
            Write-Error "Please install Terraform in WSL: 'wsl sudo apt-get install terraform'"
            Write-Error "Or install natively from https://www.terraform.io/downloads"
            return $false
        }
    }
    
    # Check Azure CLI
    Write-Info "Checking Azure CLI installation..."
    $az = Get-Command az -ErrorAction SilentlyContinue
    if ($az) {
        $azVersion = az version | ConvertFrom-Json
        Write-Success "Azure CLI found: $($azVersion.'azure-cli')"
    } else {
        Write-Error "Azure CLI not found. Please install from https://learn.microsoft.com/cli/azure/install-azure-cli"
        return $false
    }
    
    # Check Azure authentication
    Write-Info "Checking Azure authentication..."
    $azAuth = az account show 2>$null | ConvertFrom-Json
    if ($azAuth) {
        Write-Success "Authenticated as: $($azAuth.user.name)"
        Write-Success "Subscription: $($azAuth.name) ($($azAuth.id))"
    } else {
        Write-Error "Not authenticated to Azure. Running 'az login'..."
        az login
        return $false
    }
    
    return $true
}

function Validate-Configuration {
    Write-Header "Validating Configuration"
    
    # Check if terraform.tfvars exists
    if (-not (Test-Path "terraform.tfvars")) {
        Write-Error "terraform.tfvars not found!"
        return $false
    }
    Write-Success "terraform.tfvars found"
    
    # Check if variables.tf exists
    if (-not (Test-Path "variables.tf")) {
        Write-Error "variables.tf not found!"
        return $false
    }
    Write-Success "variables.tf found"
    
    # Check if main.tf exists
    if (-not (Test-Path "main.tf")) {
        Write-Error "main.tf not found!"
        return $false
    }
    Write-Success "main.tf found"
    
    # Validate Terraform syntax
    Write-Info "Validating Terraform configuration..."
    $validation = Invoke-Terraform "validate" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Terraform configuration is valid"
    } else {
        Write-Error "Terraform validation failed:"
        Write-Error $validation
        return $false
    }
    
    return $true
}

function Initialize-Terraform {
    Write-Header "Initializing Terraform"
    
    Write-Info "Running terraform init..."
    Invoke-Terraform "init"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Terraform initialized successfully"
        return $true
    } else {
        Write-Error "Terraform initialization failed"
        return $false
    }
}

function Plan-Deployment {
    Write-Header "Planning Terraform Deployment"
    
    # Check if already initialized
    if (-not (Test-Path ".terraform")) {
        Write-Warning ".terraform directory not found. Initializing Terraform..."
        if (-not (Initialize-Terraform)) {
            return $false
        }
    }
    
    Write-Info "Running terraform plan..."
    Invoke-Terraform "plan -out=tfplan"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Terraform plan created: tfplan"
        Write-Info ""
        Write-Info "Next steps:"
        Write-Info "  1. Review the plan above to see what will be created"
        Write-Info "  2. Run './deploy.ps1 -Action apply' to deploy the infrastructure"
        return $true
    } else {
        Write-Error "Terraform plan failed"
        return $false
    }
}

function Apply-Deployment {
    Write-Header "Applying Terraform Deployment"
    
    # Check if plan exists
    if (-not (Test-Path "tfplan")) {
        Write-Warning "tfplan not found. Creating new plan..."
        if (-not (Plan-Deployment)) {
            return $false
        }
    }
    
    Write-Warning "This will create Azure resources and incur costs!"
    $confirm = Read-Host "Type 'yes' to proceed with deployment"
    
    if ($confirm -ne "yes") {
        Write-Info "Deployment cancelled"
        return $false
    }
    
    Write-Info "Running terraform apply..."
    Invoke-Terraform "apply tfplan"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Terraform deployment completed successfully!"
        Write-Info ""
        Write-Info "Key outputs:"
        Invoke-Terraform "output deployment_summary"
        return $true
    } else {
        Write-Error "Terraform apply failed"
        return $false
    }
}

function Get-TerraformOutput {
    Write-Header "Terraform Outputs"
    
    if (-not (Test-Path ".terraform")) {
        Write-Error ".terraform directory not found. Run 'terraform init' first"
        return $false
    }
    
    Invoke-Terraform "output"
    return $true
}

function Show-TerraformState {
    Write-Header "Terraform State"
    
    if (-not (Test-Path ".terraform")) {
        Write-Error ".terraform directory not found. Run 'terraform init' first"
        return $false
    }
    
    Write-Info "Resources in Terraform state:"
    Invoke-Terraform "state list"
    return $true
}

function Destroy-Deployment {
    Write-Header "Destroying Terraform Deployment"
    
    Write-Warning "This will PERMANENTLY DELETE all Azure resources!"
    Write-Warning "This action cannot be undone."
    $confirm = Read-Host "Type 'yes' to proceed with destruction"
    
    if ($confirm -ne "yes") {
        Write-Info "Destruction cancelled"
        return $false
    }
    
    Write-Info "Running terraform destroy..."
    Invoke-Terraform "destroy"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Resources destroyed successfully"
        return $true
    } else {
        Write-Error "Terraform destroy failed"
        return $false
    }
}

# Main execution
switch ($Action) {
    "init" {
        if ((Check-Prerequisites) -and (Validate-Configuration)) {
            Initialize-Terraform
        }
    }
    "validate" {
        if ((Check-Prerequisites) -and (Validate-Configuration)) {
            Write-Success "All validations passed!"
        }
    }
    "plan" {
        if ((Check-Prerequisites) -and (Validate-Configuration)) {
            Plan-Deployment
        }
    }
    "apply" {
        if ((Check-Prerequisites) -and (Validate-Configuration)) {
            Apply-Deployment
        }
    }
    "output" {
        Get-TerraformOutput
    }
    "state" {
        Show-TerraformState
    }
    "destroy" {
        Destroy-Deployment
    }
    default {
        Write-Header "Azure Virtual Desktop Terraform Quick Start"
        Write-Info "Usage: .\deploy.ps1 -Action [action]"
        Write-Info ""
        Write-Info "Available actions:"
        Write-Info "  init      - Initialize Terraform and check prerequisites"
        Write-Info "  validate  - Validate configuration files"
        Write-Info "  plan      - Plan the deployment (creates tfplan)"
        Write-Info "  apply     - Apply the deployment"
        Write-Info "  output    - Show Terraform outputs"
        Write-Info "  state     - Show Terraform state"
        Write-Info "  destroy   - Destroy all resources"
        Write-Info ""
        Write-Info "Examples:"
        Write-Info "  .\deploy.ps1 -Action init"
        Write-Info "  .\deploy.ps1 -Action plan"
        Write-Info "  .\deploy.ps1 -Action apply"
    }
}

exit $LASTEXITCODE
