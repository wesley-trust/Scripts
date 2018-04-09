<#
#Script name: Connect to Partner Center
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 1
#References: 

.Synopsis
    Function that connects to Partner Center.
.Description
    Prompts for credentials if needed or if reauthentication is required, checks for active connection and matches against credentials.
.Example
    Connect-PartnerCenter -Credential $Credential
.Example
    Connect-PartnerCenter -Credential $Credential -ReAuthenticate $true
.Example
    Connect-PartnerCenter -Credential $Credential -ReAuthenticate $true -Confirm $false

#>

function Connect-PartnerCenter() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to reauthenticate with different credentials"
        )]
        [switch]
        $ReAuthenticate,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to confirm disconnection/reauthentication of active session"
        )]
        [switch]
        $Confirm
    )

    Begin {
        try {
            # Required Module
            $Module = "PartnerCenterModule"

            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Toolkit"
            . .\Check-RequiredModule.ps1

            Check-RequiredModule -Modules $Module

            # Check to see if there is an active connection
            $PCOrganizationProfile = Get-PCOrganizationProfile
            $PCOrganizationActiveDomain = $PCOrganizationProfile.domain
        }
        # Catch exception and force reauthentication
        catch [System.Management.Automation.RuntimeException] {
            $ReAuthenticate = $true
        }
        try {

            # If force reauthentication is not required
            if (!$ReAuthenticate){
                # If a connection exists
                if ($PCOrganizationProfile){
                    # If a credential exists
                    if ($Credential){
                        # Get domain from credential username
                        $UserDomain = ($Credential.UserName).Split("@")[1]

                        # Check if already connected to same Exchange domain
                        if ($UserDomain -eq $PCOrganizationActiveDomain){
                            Write-Host "`nActive connection for domain: $UserDomain"
                        }
                        else {
                            Write-Host "`nActive connection for domain: $PCOrganizationActiveDomain"
                            Write-Host "`nConnection request for domain: $UserDomain`n"
                            
                            # If confirm is true, prompt user
                            if ($Confirm){
                                $Choice = $null
                                while ($Choice -notmatch "[Y|N]"){
                                    $Choice = Read-Host "Are you sure you want to disconnect from active session? (Y/N)"
                                }
                                if ($Choice -eq "Y"){
                                    $Confirm = $false
                                }
                            }
                            if (!$Confirm){
                                # Set reauthentication flag
                                Write-Verbose "Credentials do not match active connection, forcing reauthentication"
                                $ReAuthenticate = $True
                            }
                        }
                    }            
                }
            }

            # If no active profile, or reauthentication is required 
            if (!$PCOrganizationProfile -or $ReAuthenticate) {
                
                # If no credential exist
                if (!$Credential){
                    $Credential = Get-Credential -Message "Enter Partner Center Credentials"
                }
                
                # Retrieve CSP App ID from AzureAD
                Connect-AzureAD -Credential $Credential | Out-Null
                $CSPApp = Get-AzureADApplication | Where-Object DisplayName -eq "Partner Center Native App"
                Disconnect-AzureAD
                
                # Check for ID
                if (!$CSPApp){
                    $ErrorMessage = "Unable to retrieve Azure AD App ID for Partner Center"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # If no active connection
            if (!$PCOrganizationProfile){
                # If a credential exists
                if ($Credential){
                    # Get domain from credential username
                    $CSPDomain = ($Credential.UserName).Split("@")[1]
                    
                    Write-Host "`nAuthenticating with Partner Center"
                    Add-PCAuthentication `
                        -cspAppID $CSPApp.AppID `
                        -cspDomain $CSPDomain `
                        -Credential $Credential `
                        | Out-Null
                    # Update Active Profile
                    $PCOrganizationProfile = Get-PCOrganizationProfile

                }
                else {
                    $ErrorMessage = "No credentials specified"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
            else {
                Write-Host "Active Connection to Partner Center"
            }
            return $PCOrganizationProfile
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}