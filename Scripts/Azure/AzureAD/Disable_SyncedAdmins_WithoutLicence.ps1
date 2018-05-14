<#
#Script name: Disable users in the SyncedAdmins group wihout a valid Azure AD P1 licence
#Creator: Wesley Trust
#Date: 2018-05-14
#Revision: 1
#References: 

.Synopsis
    Gets members of the SyncedAdmins group, checks whether they have an Azure AD P1 licence (for conditional access) changes Account Enabled to disabled if not.
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
    $GroupDisplayName = "SyncedAdmins",
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
    [switch]
    $LicenceStatus = "Success",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify account action if required licence status is not found"
    )]
    [switch]
    $AccountEnabled = $false
)

Begin {
    try {
        
        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1"
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
        # Execute
        Disable-UnlicencedInGroup `
            -GroupDisplayName $GroupDisplayName `
            -AzureADServicePlanId $ServicePlanId `
            -LicenceStatus $LicenceStatus `
            -AccountEnabled $AccountEnabled
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
