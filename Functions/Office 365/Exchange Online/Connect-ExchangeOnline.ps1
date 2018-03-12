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
    Connect-ExchangeOnline -Credential $Credential -ReAuthenticate

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
        $ReAuthenticate
    )

    Begin {
        try {
            # Check for active connection to Exchange Online
            $ExchangeConnection = Get-PSSession | Where-Object ComputerName -EQ outlook.office365.com

            # If no active connection, or reauthentication is required 
            if (!$ExchangeConnection -or $ReAuthenticate) {
                Write-Host "`nEnter credentials for Exchange Online"
                
                # Clear variable
                $ExchangeConnection = $null
                
                # If no credentials exist
                if (!$Credential){
                    $Credential = Get-Credential
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
            $ReminderMessage = "`nREMEMBER: Disconnect session after use, limited connections available"
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

            Write-Host "`nConnected to Exchange Online"

            # Display reminder
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
