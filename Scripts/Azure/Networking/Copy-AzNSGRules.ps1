<#
#Script name: Copy Network Security Group Rules to new network security group
#Creator: Wesley Trust
#Date: 2019-03-18
#Revision: 1
#References: 

.Synopsis
    Copy a network security group's security rules to a new NSG
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory = $false
    )]
    [pscredential]
    $AzCredential,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $AzADDomain,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $AzADTenantID,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $AzSubscriptionID,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $ResourceGroupName,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $NetworkSecurityGroupName,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $Location,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $SourceResourceGroupName,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $SourceNetworkSecurityGroupName,
    [Parameter(
        Mandatory = $false
    )]
    [switch]
    $SkipDependencyCheck = $true,
    [Parameter(
        Mandatory = $false
    )]
    [switch]
    $SkipConnectionCheck
)
Begin {
    try {

        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\Toolkit\Invoke-DependencyCheck.ps1"
        )
        # Function dot source
        foreach ($Function in $Functions) {
            . $Function
        }
    
        # Skip dependency check if switch is true
        if (!$SkipDependencyCheck) {
    
            # Dependency check for required module:
            $Module = "Az"

            Invoke-DependencyCheck -Modules $Module
        }
        
        # Check for active connection
        if (!$SkipConnectionCheck) {             
            $AzContext = Get-AzContext
            while ($AzContext) {
                
                # Safety check
                # Specify label and help text in array, '&' represents keyboard shortcut character, default choice is array index
                $Choices = @(
                    ("&Yes", "Continue with the active Azure account and subscription"),
                    ("&No", "Disconnect the active Azure account then continue")
                )
                $Title = "Active Azure Connection - $($AzContext.Name)"
                $Message = "Do you want to continue with this subscription?"
                $DefaultChoice = 0

                # Create choice collection and generate choice descriptions from choices array
                $Options = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]
                for ($Choiceindex = 0; $ChoiceIndex -lt $Choices.length; $ChoiceIndex++) {
                    $Options.Add((New-Object System.Management.Automation.Host.ChoiceDescription $Choices[$ChoiceIndex]))
                }
                
                # Prompt user
                $Result = $Host.UI.PromptForChoice($Title, $Message, $Options, $DefaultChoice)
            
                # If 'no' is chosen (Index 1), disconnect active Azure account, otherwise continue
                switch ($Result) {
                    1 {
                        $AzContext | Disconnect-AzAccount
                        $AzContext = Get-AzContext
                    }
                }
            }
        }

        # If no active connection, build parameters and connect to Azure
        if (!$AzContext) {
            $CustomParameters = @{}
            if ($AzADTenantID) {
                $CustomParameters += @{
                    TenantID = $AzADTenantID
                }
            }
            if ($AzSubscriptionID) {
                $CustomParameters += @{
                    SubscriptionID = $AzSubscriptionID
                }
            }
            if ($AzCredential) {
                $CustomParameters += @{
                    Credential = $AzCredential
                }
            }
            Connect-AzAccount @CustomParameters -ErrorAction Ignore | Tee-Object -Variable AzAccount
            
            # If connection fails, retry without specified parameters
            if (!$AzAccount) {
                Write-Verbose "Attempting connection without specified parameters"
                Connect-AzAccount
            }
        }
    }
    catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}

Process {
    try {

        # Get source network security group rules
        $AzNSG = Get-AzNetworkSecurityGroup -Name $SourceNetworkSecurityGroupName -ResourceGroupName $SourceResourceGroupName -ErrorAction Stop
        if (!$AzNSG.SecurityRules){
            $WarningMessage = "No security rules exist in source NSG."
            Write-Warning $WarningMessage
        }

        # Create resource group if it does not exist
        $ResourceGroupObject = Get-AZResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (!$ResourceGroupObject) {
            New-AZResourceGroup -Name $ResourceGroupName -Location $Location
        }

        # Create new NSG with security rules
        $NewAzNSG = New-AzNetworkSecurityGroup `
            -Name $NetworkSecurityGroupName `
            -Location $Location `
            -ResourceGroupName $ResourceGroupName `
            -SecurityRules $AzNSG.SecurityRules
        
        # If successful, summarise creation
        if ($NewAzNSG){
            Write-Host "Network Security Group: '$($NewAzNSG.Name)' created with: '$($NewAzNSG.SecurityRules.Count)' security rules"
        }
    }
    Catch {
        
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}