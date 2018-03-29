<#
#Script name: Connect Exchange Online
#Creator: Wesley Trust
#Date: 2018-03-12
#Revision: 2
#References: 

.Synopsis
    Function that connects to Exchange Online
.Description
    Checks for active session, prompts for credentials if needed, or if reauthentication is required,
    includes logic to prevent redundant connections.
.Example
    Connect-ExchangeOnline
.Example
    Connect-ExchangeOnline -Credential $Credential
.Example
    Connect-ExchangeOnline -Credential $Credential -ReAuthenticate -Force

#>

function Connect-ExchangeOnline() {
    #Parameters
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to force reauthentication"
        )]
        [switch]
        $ReAuthenticate,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to confirm disconnection of active session"
        )]
        [switch]
        $Confirm
    )

    Begin {
        try {
            # Check for connections to Exchange Online
            $ExchangeConnection = Get-PSSession | Where-Object {$_.Computername -EQ "outlook.office365.com"}
            
            # Clean up broken/closed sessions
            $ExchangeConnection | Where-Object {$_.state -ne "Opened"} | Remove-PSSession
            
            # Check for opened sessions
            $ExchangeConnection = $ExchangeConnection | Where-Object {$_.state -eq "Opened"}

            # If force reauthentication is not required
            if (!$ReAuthenticate){
                # If a connection exists
                if ($ExchangeConnection){

                    # Import active session
                    Import-PSSession $ExchangeConnection `
                        -DisableNameChecking `
                        -AllowClobber
                    
                    # Get tenant identity
                    $Tenant = Get-OrganizationConfig
                    if (!$Tenant){
                        Write-Warning "Error detecting tenant, forcing reauthentication"
                        $ReAuthenticate = $True
                    }
                    else {
                        # Set tenant identity
                        $TenantIdentity = $Tenant.Identity

                        # Get Accepted Domains
                        $AcceptedDomain = Get-AcceptedDomain

                        # Get default domain
                        $DefaultAcceptedDomain = $AcceptedDomain | Where-Object Default -EQ $true
                        $DefaultDomainName = $DefaultAcceptedDomain.DomainName

                        # If a credential exists
                        if ($Credential){
                            # Get domain from credential username
                            $UserDomain = ($Credential.UserName).Split("@")[1]

                            # Check if already connected to same Exchange domain
                            if ($UserDomain -in $AcceptedDomain.DomainName){
                                Write-Host "`nActive connection for domain: $UserDomain"
                            }
                            else {
                                Write-Host "`nActive connection for domain: $DefaultDomainName"
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
                                    $ReAuthenticate = $True
                                }
                            }
                        }
                    }            
                }
            }

            # If no active connection, or forced reauthentication is required 
            if (!$ExchangeConnection -or $ReAuthenticate) {

                # Get credentials if none exist
                if (!$Credential){
                    $Credential = Get-Credential -Message "Enter credentials for Exchange Online"
                }

                # If there is an exisiting session, disconnect
                if ($ExchangeConnection){
                    Write-Host "`nDisconnecting exisiting Exchange Online session"
                    $ExchangeConnection = $ExchangeConnection | Remove-PSSession
                }
            }
        }
        catch  {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # Variables
            $ReminderMessage = "`nREMEMBER: Disconnect session after use, limited connections available:"
            $ReminderCommand = "`nGet-PSSession | Where-Object ComputerName -EQ outlook.office365.com | Remove-PSSession`n"
            
            # If there is no connection
            if (!$ExchangeConnection) {
                Write-Host "`nConnecting to Exchange Online`n"
                
                # Create new session
                $Session = New-PSSession `
                    -ConfigurationName Microsoft.Exchange `
                    -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
                    -Credential $Credential `
                    -Authentication Basic `
                    -AllowRedirection

                # Import Session
                Import-PSSession $Session `
                    -DisableNameChecking `
                    -AllowClobber
            }

            # Get Accepted Domains
            $AcceptedDomain = Get-AcceptedDomain

            # Get tenant identity
            $Tenant = Get-OrganizationConfig
            $TenantIdentity = $Tenant.Identity
            
            # Get default domain
            $DefaultAcceptedDomain = $AcceptedDomain | Where-Object Default -EQ $true
            $DefaultDomainName = $DefaultAcceptedDomain.DomainName
            
            # Display connection messages
            Write-Host "`nConnected to Exchange Online`n"
            Write-Host "Tenant: $TenantIdentity, DefaultDomain: $DefaultDomainName"
            Write-Host $ReminderMessage -ForegroundColor Yellow -BackgroundColor Black
            Write-Host $ReminderCommand -ForegroundColor Yellow
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}