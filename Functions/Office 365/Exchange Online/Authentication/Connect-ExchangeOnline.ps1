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
            HelpMessage="Specify whether to reauthenticate connection"
        )]
        [switch]
        $ReAuthenticate,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to force reauthentication, even when connected to same tenant"
        )]
        [switch]
        $Force
    )

    Begin {
        try {
            # Check for active connection to Exchange Online
            $ExchangeConnection = Get-PSSession | Where-Object ComputerName -EQ outlook.office365.com

            # If a connection exists
            if ($ExchangeConnection){

                # Get Accepted Domains
                $AcceptedDomain = Get-AcceptedDomain

                # Get tenant identity
                $Tenant = Get-OrganizationConfig
                $TenantIdentity = $Tenant.Identity
                
                # Get default domain
                $DefaultAcceptedDomain = $AcceptedDomain | Where-Object Default -EQ $true
                $DefaultDomainName = $DefaultAcceptedDomain.DomainName
                
                # If reauthentication is not true
                If (!$ReAuthenticate){
                    # If force is true
                    if ($Force){
                        $choice = "Y"
                    }
                    else {
                        $choice = $null
                    }
                    Write-Host "`nActive connection to Exchange Online`n"
                    Write-Host "Tenant: $TenantIdentity, DefaultDomain: $DefaultDomainName`n"
                    while ($choice -notmatch "[y|n]"){
                        $choice = Read-Host "Do you want to disconnect from existing Exchange Online session? (Y/N)"
                    }
                    if ($choice -eq "Y"){
                        $ReAuthenticate = $true
                    }
                }
            }

            # If no active connection, or reauthentication is required 
            if (!$ExchangeConnection -or $ReAuthenticate) {

                # If no credentials exist
                if (!$Credential){
                    $Credential = Get-Credential -Message "Enter credentials for Exchange Online"
                }

                # If there is an exisiting session
                if ($ExchangeConnection){
                    
                    # Get domain from credential username
                    $UserDomain = ($Credential.UserName).Split("@")[1]
                
                    # Check if already connected to same Exchange domain
                    if ($UserDomain -in $AcceptedDomain.DomainName){
                        Write-Host "`nActive connection for domain: $UserDomain"
                    }
                    else {
                        Write-Host "`nDisconnecting exisiting Exchange Online session"
                        $ExchangeConnection = $ExchangeConnection | Remove-PSSession
                    }
                    if ($Force){
                        Write-Host "`nDisconnecting exisiting Exchange Online session"
                        $ExchangeConnection = $ExchangeConnection | Remove-PSSession
                    }
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
                Import-PSSession $Session
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