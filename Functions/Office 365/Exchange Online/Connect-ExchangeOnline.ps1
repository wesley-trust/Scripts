<#
#Script name: Connect Exchange Online
#Creator: Wesley Trust
#Date: 2018-03-12
#Revision: 1
#References: 

.Synopsis
    Function that connects to Exchange Online
.Description
    Function that connects to Exchange Online, checks for active session, prompts for credentials if needed, or if reauthentication is required.
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
            HelpMessage="Specify whether to reauthenticate with different credentials"
        )]
        [switch]
        $ReAuthenticate,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify whether to force reauthentication"
        )]
        [switch]
        $Force
    )

    Begin {
        try {
            # Check for active connection to Exchange Online
            $ExchangeConnection = Get-PSSession | Where-Object ComputerName -EQ outlook.office365.com

            # If no active connection, or reauthentication is required 
            if (!$ExchangeConnection -or $ReAuthenticate) {
                                
                # If no credentials exist
                if (!$Credential){               
                    Write-Host "`nEnter credentials for Exchange Online"
                    $Credential = Get-Credential
                }
                
                # If a connection exists
                if ($ExchangeConnection){
                    If (!$Force){
                        $choice = $null
                        Write-Host "`nActive connection to Exchange Online`n"
                        while ($choice -notmatch "[y|n]"){
                            $choice = Read-Host "Do you want to disconnect from existing Exchange Online session?"
                        }
                        if ($choice -eq "Y"){
                            $Force = $true
                        }
                    }
                    if ($Force) {
                        Write-Host "`nDisconnecting exisiting Exchange Online session`n"
                        $ExchangeConnection = $ExchangeConnection | Remove-PSSession
                    }
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
            $ReminderCommand = "`nGet-PSSession | Where-Object ComputerName -EQ outlook.office365.com | Remove-PSSession`n"
            
            # If there is no connection
            if (!$ExchangeConnection) {
                Write-Host "`nConnecting to Exchange Online`n"
                
                # Create new session
                $Session = New-PSSession `
                -ConfigurationName Microsoft.Exchange `
                -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
                -Credential $Credential `
                -Authentication Basic -AllowRedirection

                # Import Session
                Import-PSSession $Session
            }
            
            # Display connection messages
            Write-Host "`nConnected to Exchange Online"
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