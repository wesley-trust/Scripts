<#
#Script name: Connect to Partner Center
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 2
#References: 

.Synopsis
    Function that connects to Partner Center.
.Description
    Prompts for credentials if needed, optionally specify a CSP App ID, if not, an Azure AD lookup will be attempted.
.Example
    Connect-PartnerCenter -Credential $Credential
.Example

.Example

#>

function Connect-PartnerCenter() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optionally specify a CSP App ID, if no ID is specified, an Azure AD lookup will be attemted"
        )]
        [string]
        $CSPAppID,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Optionally specify a CSP domain, if no domain is specified, username domain is assumed"
        )]
        [string]
        $CSPDomain
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
            
            # If a credential exists, make the password read only so it can be reused
            if ($Credential) {
                $Credential.Password.MakeReadOnly()
            }
            
            # Get App ID
            if (!$CSPAppID) {
                if ($Credential) {
                    
                    # Connect to Azure AD
                    $AzureADConnection = Connect-AzureAD -Credential $Credential
                    if ($AzureADConnection){

                        # Retrieve CSP App ID from AzureAD
                        $CSPApp = Get-AzureADApplication | Where-Object DisplayName -eq "Partner Center Native App"
                        
                        # Clean-up
                        Disconnect-AzureAD
                        
                        # Check if app is returned
                        if ($CSPApp) {
                            
                            # Update App ID
                            $CSPAppID = $CSPApp.appid
                        }
                        else {
                            $ErrorMessage = "No Partner Center App ID is specified and an Azure AD lookup failed"
                            Write-Error $ErrorMessage
                            throw $ErrorMessage
                        }
                    }
                    else {
                        $ErrorMessage = "Connection to Azure AD failed, App ID lookup not possible"
                        Write-Error $ErrorMessage
                        throw $ErrorMessage
                    }
                }
            }
            
            # Get domain
            if (!$CSPDomain) {
                $CSPDomain = ($Credential.UserName).Split("@")[1]
            }
            
            # Create hashtable of custom parameters
            $CustomParameters = @{
                Credential = $Credential
                CSPAppID   = $CSPAppID
                cspDomain  = $CSPDomain
            }
            
            # Connect
            Add-PCAuthentication @CustomParameters
        }
        catch [System.Management.Automation.RuntimeException] {
            if ($CSPAppID -and $CSPDomain) {
                Write-Host "`nAuthentication attempt failed, retrying with same credentials`n"
                Add-PCAuthentication @CustomParameters
            }
        }
        catch [System.Net.WebException] {
            if ($CSPAppID -and $CSPDomain) {
                Write-Host "`nAuthentication attempt failed, prompting for retry with new credentials`n"
                $Credential = Get-Credential -Message "Enter Partner Center credentials"
                
                # Replace credential in custom parameters
                $CustomParameters.Remove("Credential")
                $CustomParameters.Add("Credential", $Credential)
                
                # Connect
                Add-PCAuthentication @CustomParameters
            }
        }
        Catch {
            Write-Error -Message $_.exception
        }
    }
    End {
        
    }
}