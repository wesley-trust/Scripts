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

function New-AzureAD-ExternalUser() {
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
        $UserType = "Member",
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to skip authentication"
        )]
        [bool]
        $SkipAuthentication = $false
    )

    Begin {
        try {
            # Required Module
            $Module = "AzureAD"
            
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
            . .\Check-RequiredModule.ps1
            
            Check-RequiredModule -Modules $Module
            
            # Connect to directory tenant
            if (!$SkipAuthentication) {
                Connect-AzureAD -Credential $Credential
            } 
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # Get Tenant domain
            $Tenant = Get-AzureADDomain | Where-Object IsInitial -eq $true
            
            # If no tenant domain
            if (!$Tenant.name){
                $ErrorMessage = "No tenant domain returned."
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # If no email address(es) are specified, request email address
            while (!$Emails) {
                $Emails = Read-Host "Enter email address(es), comma separated, to add as $UserType"
            }

            # Clean emails and create array
            $Emails = $Emails.Split(",")
            $Emails = $Emails | ForEach-Object {$_.Trim()}

            foreach ($Email in $Emails){
                
                # Get user from email
                $ExternalEmail = $Email.replace("@","_")
                $ExternalEmail = $ExternalEmail+"#EXT#@"+$Tenant.name
                $User = Get-AzureADUser -Filter "UserPrincipalName eq '$ExternalEmail'"

                # If user exists
                if ($User) {
                    $ErrorMessage = "User $Email already exists in the directory."
                    Write-Error $ErrorMessage
                }
                else {                       
                    # Create external user invitation
                    New-AzureADMSInvitation `
                    -InvitedUserEmailAddress $Email `
                    -SendInvitationMessage $True `
                    -InviteRedirectUrl "https://portal.azure.com" `
                    -InvitedUserType $UserType

                    $SuccessMessage = "User $Email has been invited to the directory as $Usertype."
                    Write-Output $SuccessMessage
                }
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
}
