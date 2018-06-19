<#
#Script name: Disable members of SecuredAdmins group without valid Azure AD P1 licence and check available licences and assignments
#Creator: Wesley Trust
#Date: 2018-05-14
#Revision: 7
#References: 

.Synopsis
    Gets members of a group, checks whether they have a licence, changes account status to disabled when non-compliant and gets licence counts/assignments.
.Description

.Example

.Example
    
#>

Param(
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify a PowerShell credential"
    )]
    [pscredential]
    $Credential,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify the display name of group to check"
    )]
    [string]
    $GroupDisplayName = "SecuredAdmins",
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify the licence service plan ID to check"
    )]
    [string]
    $ServicePlanId = "41781fb2-bc02-4b7c-bd55-b576c07bb09d",
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify service plan provisioning status required"
    )]
    [string]
    $ServicePlanProvisioningStatus = "Success",
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify account enabled status to check"
    )]
    [Nullable[bool]]
    $AccountEnabled = $true,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify required compliance status"
    )]
    [bool]
    $ComplianceStatus = $True,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify Sku consumption status to check for"
    )]
    [string]
    $SkuConsumptionStatus = "Warning",
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify Sku consumption assignment status"
    )]
    [string]
    $SkuConsumptionAssigned = $true,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to skip dependency checks"
    )]
    [switch]
    $SkipDependencyCheck,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to skip disconnection"
    )]
    [switch]
    $SkipDisconnect,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Specify whether to reauthenticate with different credentials"
    )]
    [switch]
    $ReAuthenticate
)

Begin {
    try {
        
        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Toolkit\Invoke-DependencyCheck.ps1",
            "$FunctionLocation\Azure\AzureAD\ServicePlanCompliance.ps1",
            "$FunctionLocation\Azure\AzureAD\AzureADMember.ps1"
            "$FunctionLocation\Azure\AzureAD\Test-AzureADConnection.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions) {
            . $Function
        }
        
        # Required Module
        $Module = "AzureAD"
        
        Invoke-DependencyCheck -Modules $Module

        # Check for active connection to Azure AD
        if (!$ReAuthenticate) {
            $TestConnection = Test-AzureADConnection -Credential $Credential
            if ($TestConnection.reauthenticate) {
                $ReAuthenticate = $true
            }
        }

        # If there is an active connection, clean up if required
        if ($TestConnection.ActiveConnection) {
            if ($ReAuthenticate) {
                $TestConnection.ActiveConnection = Disconnect-AzureAD | Out-Null
            }
        }

        # If no active connection, connect to Azure AD
        if (!$TestConnection.ActiveConnection -or $ReAuthenticate) {
            Write-Host "`nAuthenticating with Azure AD`n"
            $AzureADConnection = Connect-AzureAD -Credential $Credential
        }
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        
        # Throw error if not connected to Azure AD
        if (!$AzureADConnection) {
            if (!$TestConnection.ActiveConnection) {
                $ErrorMessage = "No connection to Azure AD"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }

        # Get Azure AD members
        $AzureADMembers = Get-AzureADMember `
            -GroupDisplayName $GroupDisplayName `
            -AccountEnabled $AccountEnabled

        # If users are retuned
        if ($AzureADMembers) {
            
            # Get user licence compliance
            $UserServicePlanCompliance = Get-UserServicePlanCompliance `
                -AzureADMembers $AzureADMembers `
                -ServicePlanId $ServicePlanId `
                -ServicePlanProvisioningStatus $ServicePlanProvisioningStatus

            # Set user account status, based on the compliance status
            $UserAccountEnabledOnComplianceStatus = foreach ($User in $UserServicePlanCompliance) {
                Set-UserAccountEnabledOnComplianceStatus `
                    -ObjectId $User.ObjectId `
                    -AccountEnabled $AccountEnabled `
                    -ComplianceStatus $User.ComplianceStatus
            }

            # Get Service Plan Skus
            $ServicePlanSku = Get-ServicePlanSku -ServicePlanId $ServicePlanId

            # Get Summary if a SKU is available
            if ($ServicePlanSku.SkuPartNumber) {
                $SkuConsumptionSummary = $ServicePlanSku | Get-SkuConsumptionSummary
                
                # If user compliance is equal to required status
                if ($UserServicePlanCompliance.ComplianceStatus -eq $ComplianceStatus) {
                    $FilteredUserServicePlanCompliance = $UserServicePlanCompliance | Where-Object ComplianceStatus -eq $ComplianceStatus

                    # If SKU is equal to required status
                    if ($SkuConsumptionSummary.Status -eq $SkuConsumptionStatus) {
                        $FilteredSkuConsumption = $SkuConsumptionSummary | Where-Object Status -eq $SkuConsumptionStatus
                        
                        # Get Summary of users with specified SKU consumption and assignment
                        $UserSkuConsumptionSummary = $FilteredUserServicePlanCompliance `
                            | Get-UserSkuConsumptionSummary `
                            -SkuConsumption $FilteredSkuConsumption `
                            | Where-Object SkuAssigned -eq $SkuConsumptionAssigned
                    }
                }
            }
            else {
                $WarningMessage = "No SKUs available"
                Write-Warning $WarningMessage
            }

            # Format Output for display
            Write-Host "`nUser Service Plan Compliance:`n"
            $UserServicePlanCompliance | Format-Table DisplayName, UserPrincipalName, ServicePlanName, ComplianceStatus, AccountEnabled -GroupBy ComplianceStatus
            Write-Host "Total: $($UserServicePlanCompliance.count)`n"
            if ($UserAccountEnabledOnComplianceStatus) {
                Write-Host "`nUser Action based on Service Plan Compliance:`n"
                $UserAccountEnabledOnComplianceStatus | Format-Table DisplayName, ActionStatus, AccountEnabled
            }
            else {
                Write-Verbose "No User Action Required based on Service Plan Compliance: $ComplianceStatus"
            }
            if ($ServicePlanSku) {
                Write-Host "`nSKUs with Service Plan:`n"
                $ServicePlanSku | Format-Table SkuPartNumber, CapabilityStatus, ServicePlanName, ProvisioningStatus
                Write-Host "`nSKU Consumption Analysis:`n"
                $SkuConsumptionSummary | Format-Table SkuPartNumber, AvailableUnits, Status, StatusDetail
                if ($UserSkuConsumptionSummary) {
                    Write-Host "`nUser SKU Assignment:`n"
                    $UserSkuConsumptionSummary | Format-Table DisplayName, UserPrincipalName, AccountEnabled, SkuPartNumber, SkuAssigned
                }
                else {
                    Write-Verbose "No User SKU Consumption Required based on Status: $SkuConsumptionStatus"
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
    try {
        
        # Clean up active session
        if (!$SkipDisconnect) {
            Disconnect-AzureAD 
        }
    }
    catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
