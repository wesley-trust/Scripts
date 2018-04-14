<#
#Script name: Get Azure AD Partner Center App
#Creator: Wesley Trust
#Date: 2018-04-14
#Revision: 1
#References: 

.Synopsis
    Function that connects to Azure AD to retrive the Partner Center Naive App
.Description

.Example
    Get-AzureADPCApp -Credential $Credential
.Example

.Example


#>

function Get-AzureADPCApp() {
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
            # Connect to Azure AD
            Connect-AzureAD -Credential $Credential | Out-Null
            
            # Retrieve CSP App ID from AzureAD
            $CSPApp = Get-AzureADApplication | Where-Object DisplayName -eq "Partner Center Native App"
            
            # Check if app is returned
            if ($CSPApp){
                return $CSPApp
            }
            else {
                $ErrorMessage = "No Partner Center App Id is specified and an Azure AD lookup failed"
                Write-Error $ErrorMessage
                throw $ErrorMessage
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