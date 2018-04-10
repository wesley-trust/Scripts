<#
#Script name: Connect to Exchange Online
#Creator: Wesley Trust
#Date: 2018-04-10
#Revision: 1
#References: 

.Synopsis
    Connects to Exchange Online
.Description

.Example
    
.Example
    
#>

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
        HelpMessage="Specify whether to confirm disconnection/reauthentication of active session"
    )]
    [switch]
    $Confirm
)
Begin {
    try {
        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Office365\ExchangeOnline\Authentication\Connect-ExchangeOnline.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }

    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}
Process {
    try {
        # Create hashtable of custom parameters
        $CustomParameters = @{
            Credential = $Credential;
        }
        # If switches are true, append to custom parameters
        if ($ReAuthenticate){
            $CustomParameters += @{
                ReAuthenticate = $true
            }
        }
        if ($Confirm){
            $CustomParameters += @{
                Confirm = $true
            }
        }

        # Connect to Exchange Online with custom parameters
        Connect-ExchangeOnline @CustomParameters

    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}