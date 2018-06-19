<#
#Script name: Connect to Partner Center
#Creator: Wesley Trust
#Date: 2018-04-10
#Revision: 2
#References: 

.Synopsis
    Connects to Partner Center
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
        HelpMessage="Specify whether to reauthenticate with different credentials"
    )]
    [switch]
    $ReAuthenticate
)

Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\PartnerCenter\Authentication\Test-PartnerCenterConnection.ps1",
            "$FunctionLocation\PartnerCenter\Authentication\Connect-PartnerCenter.ps1",
            "$FunctionLocation\Toolkit\Invoke-DependencyCheck.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
                
        # Required Module
        $Module = "PartnerCenterModule,AzureAD"
        
        Invoke-DependencyCheck -Modules $Module
        
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        if (!$Credential){
            $Credential = Get-Credential -Message "Enter Partner Center credentials"
        }

        # Check for active connection
        if (!$ReAuthenticate){
            $TestConnection = Test-PartnerCenterConnection -Credential $Credential
            if ($TestConnection.reauthenticate){
                $ReAuthenticate = $true
            }
        }

        # If no active connection, connect
        if (!$TestConnection.ActiveConnection -or $ReAuthenticate){
            Write-Host "`nAuthenticating with Partner Center`n"
            $PartnerCenterConnection = Connect-PartnerCenter -Credential $Credential
            if ($PartnerCenterConnection){
                return $PartnerCenterConnection
            }
            else{
                $ErrorMessage = "Unable to connect to Partner Center"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}