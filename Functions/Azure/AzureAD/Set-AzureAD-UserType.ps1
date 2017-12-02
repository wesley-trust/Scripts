<#
#Script name: Sets Azure AD tenant user type for multiple email addresses.
#Creator: Wesley Trust
#Date: 2017-12-01
#Revision: 1
#References: 

.Synopsis
    Function that connects to an Azure AD tenant and sets directory user type (by default Member is specified).
.Description

.Example
    Set-AzureAD-UserType -Credential $Credential -Emails "wesley.trust@example.com" -UserType $UserType
.Example
    
#>

function Set-AzureAD-UserType() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify a PowerShell credential"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify email address(es) of directory to change"
        )]
        [string[]]
        $Emails,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify user type to change to (Default: Member)"
        )]
        [string]
        $UserType = "Member"
    )

    Begin {
        try {
            # Variables
            $Module = "MSOnline"
            
            # Check if module is installed
            $ModuleCheck = Get-Module -ListAvailable | Where-Object Name -eq $Module
            
            # If not installed, install the module
            if (!$ModuleCheck){

                Install-Module -Name $Module -AllowClobber -Force -ErrorAction Stop
            }
            
            # Connect to directory tenant
            Connect-MsolService -Credential $Credential
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # If no email address(es) are specified, request email address
            while (!$Emails) {
                $Emails = Read-Host "Enter user email address(es), comma separated, to change to $UserType"
            }
            
            # Get Tenant domain
            if (!$Tenant){
                $Tenant = Get-MsolCompanyInformation | Select-Object InitialDomain
            }

            foreach ($Email in $Emails){
                
                # Get user from email
                $User = Get-MsolUser | Where-Object {$_.SignInName -EQ $Email}
                
                # If there is no user, check for external sign in address
                if (!$User){
                    $Email = $Email.replace("@","_")
                    $Email = $Email+"#EXT#@"+$Tenant.initialdomain
                    $User = Get-MsolUser | Where-Object {$_.SignInName -EQ $Email}
                }

                # If user exists
                if ($User) {
                    
                    # Check if user is already the user type to change to
                    $UserCheck = $User | Where-Object  {$_.UserType -EQ $UserType}
                    if ($UserCheck){
                        $ErrorMessage = "User $Email is already a $UserType in the directory."
                        Write-Error $ErrorMessage
                    }
                    else {                       
                        
                        # Set user to new user type
                        $User | Set-MsolUser -UserType $UserType -ErrorAction Stop
                        $SuccessMessage = "User $Email has been changed to $UserType in the directory."
                        Write-Output $SuccessMessage
                    }
                }
                else {
                    $ErrorMessage = "$Email does not exist in the directory."
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
        
    }
}
