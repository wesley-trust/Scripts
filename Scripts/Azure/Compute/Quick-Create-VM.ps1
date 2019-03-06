<#
#Script name: Quick create Azure virtual machine
#Creator: Wesley Trust
#Date: 2019-03-04
#Revision: 1
#References: 

.Synopsis
    Quickly create a VM, using parallel jobs with the new simplified parameters of the Az module command.
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
    [pscredential]
    $AzADTenantID,
    [Parameter(
        Mandatory = $false
    )]
    [pscredential]
    $AzSubscriptionID,
    [Parameter(
        Mandatory = $false
    )]
    [pscredential]
    $VMCredential,
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $VMName = "WesDev-",
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $Location = "uksouth",
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $VMSize = "Standard_D2s_v3",
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $ResourceGroupName = "WesDevVMTest",
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $VirtualNetwork = "WesDevVMTest-vnet",
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $VMSubnet = "default",
    [Parameter(
        Mandatory = $false
    )]
    [string]
    $VMImage = "Win2016Datacenter",
    [Parameter(
        Mandatory = $false
    )]
    [int]
    $VMRandomStringLength = 6 ,
    [Parameter(
        Mandatory = $false
    )]
    [int]
    $VMCount = 10,
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
            "$FunctionLocation\Toolkit\New-RandomString.ps1",
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
                $Options = [System.Management.Automation.Host.ChoiceDescription[]] @('&Yes', '&No')
                $Title = "Active Azure Connection - $($AzContext.Name)"
                $Message = "Do you want to continue?"
                $Result = $host.ui.PromptForChoice($title, $message, $options, 0)
            
                # If no is chosen (Index 1), disconnect active Azure account
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

        # Create resource group if it does not exist
        $ResourceGroupObject = Get-AZResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (!$ResourceGroupObject) {
            New-AZResourceGroup -Name $ResourceGroupName -Location $Location
        }

        # Request VM credentials if none are provided
        if (!$VMCredential) {
            $VMCredential = Get-Credential -Message "Specify VM Credentials"
        }
        
        # Deploy VM as parallel jobs
        $NewAzVM = foreach ($VM in 1..$VMCount) {
            
            # Create random string for VM name
            $RandomString = New-RandomString -CharacterLength $VMRandomStringLength -Alphanumeric
            $RandomVMName = $VMName + $RandomString

            New-AzVM `
                -Name $RandomVMName `
                -Location $Location `
                -Size $VMSize `
                -ResourceGroupName $ResourceGroupName `
                -VirtualNetworkName $VirtualNetwork `
                -SubnetName $VMSubnet `
                -Credential $VMCredential `
                -Image $VMImage `
                -AsJob
        }

        # Display as table
        $NewAZVM | Format-Table

        # Get all jobs and wait for completion
        Get-Job | Wait-Job | Format-Table
    }
    Catch {
        
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}