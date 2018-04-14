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
            throw $_.exception
        }
    }
    
    Process {
        try {
            # Check to see if there is an active connection
            $PCOrganizationProfile = Get-PCOrganizationProfile
            $PCOrganizationActiveDomain = $PCOrganizationProfile.domain
            
            # If a connection exists
            if ($PCOrganizationProfile){
                Write-Host "`nActive Partner Center connection for $PCOrganizationActiveDomain`n"
                $ActiveConnection = $True
                # If a credential exists
                if ($Credential){
                    # Get domain from credential username
                    $UserDomain = ($Credential.UserName).Split("@")[1]

                    # Check if already connected to same domain
                    if (!$UserDomain -eq $PCOrganizationActiveDomain){
                        Write-Host "`nConnection request for domain: $UserDomain`n"
                        $ActiveConnection = $false
                    }
                }
            return $ActiveConnection
            }
        }
        Catch {
            #Write-Error -Message $_.exception
            #throw $_.exception
        }
    }
    End {
        
    }
}