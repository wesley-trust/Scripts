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
            Mandatory = $false,
            HelpMessage = "Specify PowerShell credential object"
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

            # Check if module is installed
            Write-Host "`nPerforming Connection Check"
            Write-Host "`nRequired Connection(s): Azure AD"

            $ObjectProperties = @{
                Connection = "Azure RM"
            }
            
            # Check for active Azure AD session
            $CurrentSession = Get-AzureADCurrentSessionInfo 2> $null
            
            # If a connection exists
            if ($CurrentSession) {
                $ObjectProperties += @{
                    ActiveConnection = $true
                }
                
                # If a credential exists
                if ($Credential) {
                    
                    # Get domain from credential username
                    $UserAccount = $Credential.UserName

                    # Check if already connected to same domain
                    if ($UserAccount -ne $CurrentSessionAccount) {
                        $ObjectProperties += @{
                            CredentialCheck = $false
                            Reauthenticate  = $true
                        }
                    }
                }
            }
            else {
                $ObjectProperties += @{
                    ActiveConnection = $false
                }
            }
            New-Object -TypeName psobject -Property $ObjectProperties
        }
        Catch {
            #Write-Error -Message $_.exception
        }
    }
    End {
        
    }
}