<#
#Script name: Set-AzureAD-UserType
#Creator: Wesley Trust
#Date: 2017-12-03
#Revision: 1
#References: 

.Synopsis
    Function that connects to an Azure AD tenant and sets directory user type (by default to Member).
.Description

.Example
    Set-AzureAD-UserType -Credential $Credential -Emails "wesley.trust@example.com" -UserType $UserType
.Example
    
#>
function Set-AzureADUserType {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify email address(es) of directory to change"
        )]
        [string[]]
        $Emails,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify user type to change to (Default: Member)"
        )]
        [ValidateSet("Guest", "Member")] 
        [string]
        $UserType = "Member"
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
                $Emails = Read-Host "Enter email address(es), comma separated, to change to $UserType"
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
                    
                    # Check if user is already the user type to change to
                    $UserCheck = $User | Where-Object {$_.UserType -EQ $UserType}
                    if ($UserCheck) {
                        $ErrorMessage = "User $Email is already a $UserType in the directory."
                        Write-Error $ErrorMessage
                    }
                    else {                       
                        
                        # Set user to new user type
                        $User | Set-AzureADUser -UserType $UserType -ErrorAction Stop
                        $SuccessMessage = "User $Email has been changed to $UserType in the directory."
                        Write-Output $SuccessMessage
                    }
                }
                else {
                    $ErrorMessage = "User $Email does not exist in the directory."
                    Write-Error $ErrorMessage
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
