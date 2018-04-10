<#
#Script name: Connect to Azure subscription
#Creator: Wesley Trust
#Date: 2018-04-10
#Revision: 1
#References: 

.Synopsis
    Connects to an Azure RM subscription
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter the subscription ID"
    )]
    [string]
    $SubscriptionID,
    [Parameter(
        Mandatory=$false,
        HelpMessage="Enter a subscription name"
    )]
    [string]
    $SubscriptionName,
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

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Azure\Authentication\Connect-AzureRM.ps1",
            "$FunctionLocation\Toolkit\Check-RequiredModule.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions){
            . $Function
        }
        
        # Required Module
        $Module = "AzureRM"
        
        Check-RequiredModule -Modules $Module

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
            SubscriptionID = $SubscriptionID;
            SubscriptionName = $SubscriptionName;
            Credential = $Credential;
        }
        # If switches are true, append to custom parameters
        if ($ReAuthenticate){
            $CustomParameters += @{
                ReAuthenticate = $true
            }
        }
        if ($Force){
            $CustomParameters += @{
                Force = $true
            }
        }

        # Connect to Azure RM Subscription with custom parameters
        Connect-AzureRM @CustomParameters

    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}