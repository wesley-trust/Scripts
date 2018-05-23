<#
#Script name: Disable members of RestrictedAdmins group without valid Azure AD P1 licence and check available licences and assignments
#Creator: Wesley Trust
#Date: 2018-05-14
#Revision: 4
#References: 

.Synopsis
    Gets members of a group, checks whether they have a licence, changes account status to disabled when non-compliant and gets licence counts/assignments.
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
        HelpMessage="Specify account enabled status to check"
    )]
    [Nullable[bool]]
    $AccountEnabled = $true,
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
        $ConnectionStatus = Connect-AzureAD -Credential $Credential
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        # Get user licence compliance
        $AzureADMembers = Get-AzureADMembers `
            -GroupDisplayName $GroupDisplayName `
            -AccountEnabled $AccountEnabled

        # If users are retuned
        if ($AzureADMembers){
            # Get user licence compliance
            $UserServicePlanCompliance = Get-UserServicePlanCompliance `
                -AzureADMembers $AzureADMembers `
                -ServicePlanId $ServicePlanId `
                -ServicePlanProvisioningStatus $ServicePlanProvisioningStatus

            # Set user account status, based on the compliance status
            $UserAccountEnabledOnComplianceStatus = $UserServicePlanCompliance | ForEach-Object {
                Set-UserAccountEnabledOnComplianceStatus `
                    -ObjectId $_.ObjectId `
                    -AccountEnabled $AccountEnabled `
                    -ComplianceStatus $_.ComplianceStatus
            }

            # Get Service Plan Skus
            $ServicePlanSku = Get-ServicePlanSku -ServicePlanId $ServicePlanId

            # Get Summary if a SKU is available
            if ($ServicePlanSku.SkuPartNumber){
                $SkuConsumptionSummary = $ServicePlanSku | Get-SkuConsumptionSummary
                
                # If user compliance is equal to required status
                if ($UserServicePlanCompliance.ComplianceStatus -eq $ComplianceStatus){
                    $FilteredUserServicePlanCompliance = $UserServicePlanCompliance | Where-Object ComplianceStatus -eq $ComplianceStatus

                    # If SKU is equal to required status
                    if ($SkuConsumptionSummary.Status -eq $SkuConsumptionStatus){
                        $FilteredSkuConsumption = $SkuConsumptionSummary | Where-Object Status -eq $SkuConsumptionStatus
                        
                        # Get Summary of users with specified SKU consumption
                        $UserSkuConsumptionSummary = $FilteredUserServicePlanCompliance | Get-UserSkuConsumptionSummary -SkuConsumption $FilteredSkuConsumption
                    }
                }
            }
            else {
                $WarningMessage = "No SKUs available"
                Write-Warning $WarningMessage
            }

            # Format Output
            Write-Host "`nUser Service Plan Compliance:`n"
            $UserServicePlanCompliance | Format-Table DisplayName,UserPrincipalName,ServicePlanName,ComplianceStatus,AccountEnabled
            
            if ($UserAccountEnabledOnComplianceStatus){
                Write-Host "`nUser Action on Service Plan Compliance:`n"
                $UserAccountEnabledOnComplianceStatus | Format-Table DisplayName,ActionStatus,AccountEnabled
            }

            if ($ServicePlanSku){
                Write-Host "`nSKUs with Service Plan:`n"
                $ServicePlanSku | Format-Table SkuPartNumber,CapabilityStatus,ServicePlanName,ProvisioningStatus
                
                Write-Host "`nSKU Consumption Analysis:`n"
                $SkuConsumptionSummary | Format-Table SkuPartNumber,AvailableUnits,Status,StatusDetail
                
                if ($UserSkuConsumptionSummary){
                    Write-Host "`nUser SKU Assignment:`n"
                    $UserSkuConsumptionSummary | Format-Table DisplayName,UserPrincipalName,AccountEnabled,SkuPartNumber,SkuAssigned
                }
            }
            else {
                Write-Output "No available SKUs with the Service Plan, an appropriate SKU, if required, should be provisioned"
            }
        }
        else {
            $ErrorMessage = "No Azure AD members returned"
            Write-Error $ErrorMessage
            throw $ErrorMessage
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
