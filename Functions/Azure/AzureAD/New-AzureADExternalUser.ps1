<#
#Script name: New-AzureAD-ExternalUser
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 2
#References: 

.Synopsis
    Function that connects to an Azure AD tenant, invites external user and sets directory user type (by default to Member).
.Description

.Example
    New-AzureAD-ExternalUser -Credential $Credential -Emails "wesley.trust@example.com" -UserType $UserType
.Example
    
#>
function New-AzureADExternalUser {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify email address(es) comma seperated"
        )]
        [string[]]
        $Emails,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify user type (Default: Member)"
        )]
        [ValidateSet("Guest", "Member")] 
        [string]
        $UserType
    )

    Begin {
        try {

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
            if (!$Tenant.name) {
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
            $Emails = $Emails.Trim()

            foreach ($Email in $Emails) {
                
                # Get user from email
                $ExternalEmail = $Email.replace("@", "_")
                $ExternalEmail = $ExternalEmail + "#EXT#@" + $Tenant.name
                $User = Get-AzureADUser -Filter "UserPrincipalName eq '$ExternalEmail'"

                # If user exists
                if ($User) {
                    $ErrorMessage = "User $Email already exists in the directory."
                    Write-Error $ErrorMessage
                }
                else {                       
                    
                    # Create external user invitation
                    $AzureADMSInvitation = New-AzureADMSInvitation `
                        -InvitedUserEmailAddress $Email `
                        -SendInvitationMessage $True `
                        -InviteRedirectUrl "https://portal.azure.com" `
                        -InvitedUserType $UserType
                    
                    # Status report
                    if ($AzureADMSInvitation.status -eq "PendingAcceptance") {
                        return $AzureADMSInvitation
                        $SuccessMessage = "User $Email has been invited to the directory as $Usertype."
                        Write-Host $SuccessMessage
                    }
                    else {
                        
                        # If there was a response with an unexpected status, return this
                        if ($AzureADMSInvitation) {
                            return $AzureADMSInvitation
                        }
                        $ErrorMessage = "An unknown error has occurred for $Email"
                        Write-Error $ErrorMessage
                    }
                }
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        try {
            
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
}
