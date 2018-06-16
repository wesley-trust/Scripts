<#
#Script name: Test Azure AD connection
#Creator: Wesley Trust
#Date: 2018-05-30
#Revision: 1
#References: 

.Synopsis
    Function that tests for an active connection to Azure AD
.Description
    Including whether correct credentials are in use
.Example
    Test-AzureADConnection -Credential $Credential
.Example

.Example


#>

function Test-AzureADConnection() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
    
    Process {
        try {
            # Check for active Azure AD session
            $CurrentSession = Get-AzureADCurrentSessionInfo 2> $null
            
            # If a connection exists
            if ($CurrentSession){
                $CurrentSessionAccount = $CurrentSession.Account
                Write-Host "`nActive Azure AD connection for $CurrentSessionAccount`n"
                $ActiveConnection = $True
                
                # If a credential exists
                if ($Credential){
                    
                    # Get domain from credential username
                    $UserAccount = $Credential.UserName

                    # Check if already connected to same domain
                    if ($UserAccount -ne $CurrentSessionAccount){
                        Write-Host "`nAccount credentials do not match active account: $UserAccount, reauthenticating`n"
                        $Reauthenticate = $true
                    }
                }
                $Properties = @{
                    ActiveConnection = $ActiveConnection
                    ReAuthenticate = $ReAuthenticate
                }
                return $Properties
            }
        }
        Catch {
            #Write-Error -Message $_.exception
        }
    }
    End {
        
    }
}