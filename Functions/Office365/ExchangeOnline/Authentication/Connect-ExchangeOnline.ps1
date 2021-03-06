<#
#Script name: Connect Exchange Online
#Creator: Wesley Trust
#Date: 2018-03-12
#Revision: 4
#References: 

.Synopsis
    Function that connects to Exchange Online
.Description
    Clears broken sessions, imports active session if available, prompts for credentials if needed, or if reauthentication is required,
    includes logic to prevent reauthenticating active sessions (unless confirm switch is set), as well as delegated access support.
.Example
    Connect-ExchangeOnline
.Example
    Connect-ExchangeOnline -Credential $Credential
.Example
    Connect-ExchangeOnline -Credential $Credential -ReAuthenticate -Confirm

#>

function Connect-ExchangeOnline() {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify PowerShell credential object"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to force reauthentication"
        )]
        [switch]
        $ReAuthenticate,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to confirm disconnection/reauthentication of active session"
        )]
        [switch]
        $Confirm,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify tenant to use for delegated authentication"
        )]
        [string]
        $TenantDomain,
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Specify whether to use delegated authentication"
        )]
        [switch]
        $DelegatedAuthentication
    )

    Begin {
        try {

            # Check for connections to Exchange Online
            $ExchangeConnection = Get-PSSession | Where-Object {$_.Computername -EQ "ps.outlook.com"}

            # Clean up broken sessions
            $NonOpenedSessions = $ExchangeConnection | Where-Object {$_.state -ne "Opened"}
            if ($NonOpenedSessions) {
                $NonOpenedSessions | Remove-PSSession
                Write-Verbose "Detected non-opened sessions, cleaning up by removing stale sessions"
            }

            # Check for opened sessions that are available
            $ExchangeConnection = $ExchangeConnection | Where-Object {$_.state -eq "Opened" -and $_.Availability -eq "Available"}

            # Check for multiple connections
            if ($ExchangeConnection.count -gt 1) {
                Write-Verbose "Function does not support more than one open connection, forcing reauthentication"
                Write-Warning "Connection will be reauthenticated as there is more than one active connection"
                $ReAuthenticate = $True
            }

            # If force reauthentication is not required
            if (!$ReAuthenticate) {
                # If a connection exists
                if ($ExchangeConnection) {

                    # Attempt to import active session
                    Import-PSSession $ExchangeConnection `
                        -DisableNameChecking `
                        -AllowClobber
                    
                    # Get tenant identity
                    $OrganizationConfig = Get-OrganizationConfig
                    if (!$OrganizationConfig) {
                        Write-Verbose "Error detecting organisation configuration, forcing reauthentication"
                        Write-Warning "Connection will be reauthenticated as a valid tenant has not been detected"
                        $ReAuthenticate = $True
                    }
                    else {
                        # Get Accepted Domains
                        $AcceptedDomain = Get-AcceptedDomain

                        # Get default domain
                        $DefaultAcceptedDomain = $AcceptedDomain | Where-Object Default -EQ $true

                        # If delegation is true, check existing connection to tenant, bypassing credential check
                        if ($DelegatedAuthentication) {
                            Write-Host "`nActive connection for tenant: $($DefaultAcceptedDomain.DomainName)`n"
                            if ($DefaultAcceptedDomain.DomainName -ne $TenantDomain) {
                                Write-Host "`nConnection request for tenant: $TenantDomain`n"
        
                                # If confirm is true, prompt user
                                if ($Confirm) {
                                    $Choice = $null
                                    while ($Choice -notmatch "[Y|N]") {
                                        $Choice = Read-Host "Are you sure you want to disconnect from active session? (Y/N)"
                                    }
                                    if ($Choice -eq "Y") {
                                        $Confirm = $false
                                    }
                                }
                                if (!$Confirm) {
                                    # Set reauthentication flag
                                    Write-Verbose "Tenant does not match active connection, forcing reauthentication"
                                    $ReAuthenticate = $True
                                }
                            }
                        }
                        else {
                        
                            # If a credential exists, check current domain
                            if ($Credential) {

                                # Get domain from credential username
                                $UserDomain = ($Credential.UserName).Split("@")[1]

                                # Check if already connected to same Exchange domain
                                if ($UserDomain -in $AcceptedDomain.DomainName) {
                                    Write-Host "`nActive connection for domain: $UserDomain`n"
                                }
                                else {
                                    Write-Host "`nActive connection for domain: $($DefaultAcceptedDomain.DomainName)`n"
                                    Write-Host "`nConnection request for domain: $UserDomain`n"
        
                                    # If confirm is true, prompt user
                                    if ($Confirm) {
                                        $Choice = $null
                                        while ($Choice -notmatch "[Y|N]") {
                                            $Choice = Read-Host "Are you sure you want to disconnect from active session? (Y/N)"
                                        }
                                        if ($Choice -eq "Y") {
                                            $Confirm = $false
                                        }
                                    }
                                    if (!$Confirm) {
                                        # Set reauthentication flag
                                        Write-Verbose "Credentials do not match active connection, forcing reauthentication"
                                        $ReAuthenticate = $True
                                    }
                                }
                            }
                        }            
                    }
                }
            }

            # If no active connection, or forced reauthentication is required 
            if (!$ExchangeConnection -or $ReAuthenticate) {

                # Get credentials if none exist
                if (!$Credential) {
                    $Credential = Get-Credential -Message "Enter credentials for Exchange Online"
                }

                # If there is an exisiting session, disconnect
                if ($ExchangeConnection) {
                    Write-Host "`nDisconnecting exisiting Exchange Online session"
                    $ExchangeConnection = $ExchangeConnection | Remove-PSSession
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
            # Variables
            $ReminderMessage = "`nREMEMBER: Disconnect session after use, limited connections available:"
            $ReminderCommand = "`nGet-PSSession | Where-Object ComputerName -EQ ps.outlook.com | Remove-PSSession`n"
            $ConnectionUri = "https://ps.outlook.com/powershell-liveid"
            $DelegatedOrganisation = "?DelegatedOrg=$TenantDomain"

            # Alter connection URL if delegation is true and tenant is specified
            if ($DelegatedAuthentication) {
                if ($TenantDomain) {
                    $ConnectionUri = $ConnectionUri + $DelegatedOrganisation
                }
                else {
                    $ErrorMessage = "No tenant specificed for delegated authentication"
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }
            
            # If there is no connection
            if (!$ExchangeConnection) {
                Write-Host "`nConnecting to Exchange Online`n"
                
                # Create new session
                $Session = New-PSSession `
                    -ConfigurationName Microsoft.Exchange `
                    -ConnectionUri $ConnectionUri `
                    -Credential $Credential `
                    -Authentication Basic `
                    -AllowRedirection
                
                    if ($Session) {
                    # Import Session
                    Import-PSSession $Session `
                        -DisableNameChecking `
                        -AllowClobber
                }
                else {
                    $ErrorMessage = "Unable to establish session. Conditional Access may be blocking the connection. If MFA is enabled, use Connect-EXOPSSession."
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }

            # Get Accepted Domains
            $AcceptedDomain = Get-AcceptedDomain

            # Get Organization Config
            $OrganizationConfig = Get-OrganizationConfig
            
            # Get default domain
            $DefaultAcceptedDomain = $AcceptedDomain | Where-Object Default -EQ $true
            
            # Display connection messages
            Write-Host "`nConnected to Exchange Online`n"
            Write-Host "Tenant: $($OrganizationConfig.Identity), Domain: $($DefaultAcceptedDomain.DomainName)"
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