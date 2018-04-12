<#
#Script name: New-AzureAD-ExternalUser
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 1
#References: 

.Synopsis
    Function that connects to an Azure AD tenant, invites external user and sets directory user type (by default to Member).
.Description

.Example
    New-AzureAD-ExternalUser -Credential $Credential -Emails "wesley.trust@example.com" -UserType $UserType
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
        HelpMessage="Specify email address(es)"
    )]
    [string[]]
    $Emails,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify user type (Default: Member)"
    )]
    [ValidateSet("Guest","Member")] 
    [string]
    $UserType = "Member"
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
        # New Azure AD External User
        New-AzureAD-ExternalUser `
            -Credential $Credential `
            -Emails $Emails `
            -UserType $UserType
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
