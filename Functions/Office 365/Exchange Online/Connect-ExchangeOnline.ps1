<#
#Script name: Connect Exchange Online
#Creator: Wesley Trust
#Date: 2018-03-12
#Revision: 1
#References: 

.Synopsis
    Function that connects to Exchange Online
.Description
    Function that connects to Exchange Online, prompts for credentials.
.Example
    Connect-ExchangeOnline -Credential $Credential
.Example
    

#>

function Connect-ExchangeOnline() {
    #Parameters
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
            # If no credentials exist, prompt for credentials
            if (!$Credential){
                Write-Host "Enter Exchange Online credentials"
                $Credential = Get-Credential
            }

            # Create new session
            $Session = New-PSSession `
                -ConfigurationName Microsoft.Exchange `
                -ConnectionUri https://outlook.office365.com/powershell-liveid/ `
                -Credential $Credential `
                -Authentication Basic -AllowRedirection
            
            # Import Session
            Import-PSSession $Session
            Write-Host "Remember to disconnect session after use with:" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host 'Remove-PSSession $Session' -ForegroundColor Yellow -BackgroundColor Black
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
