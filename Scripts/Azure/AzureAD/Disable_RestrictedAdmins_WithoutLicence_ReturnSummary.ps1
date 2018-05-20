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
        HelpMessage="Specify licence status required"
    )]
    [string]
    $LicenceStatus = "Success",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify account enabled status if required licence status is not found"
    )]
    [bool]
    $AccountEnabled = $false
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
        $GroupMemberServicePlanCompliance = Get-GroupMemberServicePlanCompliance `
            -GroupDisplayName $GroupDisplayName `
            -ServicePlanId $ServicePlanId `
            -LicenceStatus $LicenceStatus `
            -AccountEnabled $AccountEnabled

        # Set user account status, based on the compliance status
        $UserAccountEnabledOnComplianceStatus = $GroupMemberServicePlanCompliance | ForEach-Object {
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
        }

        # Output
        $GroupMemberServicePlanCompliance
        $UserAccountEnabledOnComplianceStatus
        if ($SkuConsumptionSummary){
            $SkuConsumptionSummary
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
