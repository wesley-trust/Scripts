<#
#Script name: Disable members of SyncedAdmins group without valid Azure AD P1 licence and check available licences
#Creator: Wesley Trust
#Date: 2018-05-14
#Revision: 2
#References: 

.Synopsis
    Gets members of a group, checks whether they have a licence, changes account status to disabled when non-compliant and gets licence counts.
.Description

.Example

.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify a PowerShell credential"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the display name of group to check"
    )]
    [string]
    $GroupDisplayName = "RestrictedAdmins",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify the licence service plan ID to check"
    )]
    [string]
    $ServicePlanId = "41781fb2-bc02-4b7c-bd55-b576c07bb09d",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify service plan provisioning status required"
    )]
    [string]
    $ServicePlanProvisioningStatus = "Success",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify account enabled status if required licence status is not found"
    )]
    [bool]
    $AccountEnabled = $false,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify required compliance status"
    )]
    [bool]
    $ComplianceStatus = $True,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify Sku consumption status to check for"
    )]
    [string]
    $SkuConsumptionStatus = "Warning"
)

Begin {
    try {
        
        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1",
            "$FunctionLocation\Azure\AzureAD\ServicePlanCompliance.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "AzureAD"
        
        Check-RequiredModule -Modules $Module

        # Connect to directory tenant
        Connect-AzureAD -Credential $Credential
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        # Get user licence compliance
        $UserServicePlanCompliance = Get-UserServicePlanCompliance `
            -GroupDisplayName $GroupDisplayName `
            -ServicePlanId $ServicePlanId `
            -ServicePlanProvisioningStatus $ServicePlanProvisioningStatus `
            -AccountEnabled $AccountEnabled

        # Set user account status, based on the compliance status
        $UserAccountEnabledOnComplianceStatus = $UserServicePlanCompliance | ForEach-Object {
            Set-UserAccountEnabledOnComplianceStatus `
                -ObjectId $_.$ObjectId `
                -AccountEnabled $AccountEnabled `
                -ComplianceStatus $_.$ComplianceStatus
        }

        # Get Service Plan Skus
        $ServicePlanSku = Get-ServicePlanSku -ServicePlanId $ServicePlanId

        # Get Summary if a SKU is available
        if ($ServicePlanSku.SkuPartNumber){
            $SkuConsumptionSummary = $ServicePlanSku | Get-SkuConsumptionSummary
            
            # If user compliance is equal to required status
            if ($UserServicePlanCompliance -eq $ComplianceStatus){
                $FilteredUserServicePlanCompliance | Where-Object Status -eq $ComplianceStatus

                # If SKU is equal to required status
                if ($SkuConsumptionSummary.Status = $SkuConsumptionStatus){
                    $FilteredSkuConsumption = $SkuConsumptionSummary | Where-Object Status -eq $SkuConsumptionStatus
                    
                    # Get Summary of users with a warning Sku
                    $UserSkuConsumptionSummary = $FilteredUserServicePlanCompliance | Get-UserSkuConsumptionSummary -SkuConsumption $FilteredSkuConsumption
                }
            }
        }

        # Output
        $UserServicePlanCompliance
        $UserAccountEnabledOnComplianceStatus
        if ($SkuConsumptionSummary){
            $SkuConsumptionSummary
            if ($UserSkuConsumptionSummary){
                $UserSkuConsumptionSummary
            }
        }
        else {
            $ServicePlanSku
        }
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    # Disconnect
    Disconnect-AzureAD 
}
