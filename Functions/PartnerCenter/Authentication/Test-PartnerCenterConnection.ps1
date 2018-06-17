<#
#Script name: Test Partner Center connection
#Creator: Wesley Trust
#Date: 2018-04-14
#Revision: 1
#References: 

.Synopsis
    Function that tests for an active connection to Partner Center
.Description
    Including whether correct credentials are in use
.Example
    Test-PartnerCenterConnection -Credential $Credential
.Example

.Example

#>
function Test-PartnerCenterConnection() {
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
            
            # Check to see if there is an active connection
            $PCOrganizationProfile = Get-PCOrganizationProfile
            
            # If a connection exists
            if ($PCOrganizationProfile){
                $PCOrganizationActiveDomain = $PCOrganizationProfile.domain
                Write-Host "`nActive Partner Center connection for $PCOrganizationActiveDomain`n"
                $ActiveConnection = $True
                
                # If a credential exists
                if ($Credential){
                    
                    # Get domain from credential username
                    $UserDomain = ($Credential.UserName).Split("@")[1]

                    # Check if already connected to same domain
                    if (!$UserDomain -eq $PCOrganizationActiveDomain){
                        Write-Host "`nAccount credentials do not match active domain: $UserDomain, reauthenticating`n"
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