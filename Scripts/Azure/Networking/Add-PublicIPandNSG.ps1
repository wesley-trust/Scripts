<#
#Script name: Associate public IP address and network security group
#Creator: Wesley Trust
#Date: 2019-03-18
#Revision: 1
#References: 

.Synopsis
    Associates public IP address and network security group to VMs failed over with ASR
.Description
    Assets:
        Az.Accounts
        Az.Automation
        Az.Compute
        Az.Resources
        Az.Network
.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory = $false
    )]
    [object]$RecoveryPlanContext,
    [Parameter(
        Mandatory = $false
    )]
    [string]$ConnectionName = "AzureRunAsConnection",
    [Parameter(
        Mandatory = $false
    )]
    [string]$AutomationAccountName,
    [Parameter(
        Mandatory = $false
    )]
    [string]$AzSubscriptionID,
    [Parameter(
        Mandatory = $false
    )]
    [string]$ResourceGroupName
)

try {
    # Get the service principal of the connection
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName
}
        
# Catch when Azure Automation command is not found
catch [System.Management.Automation.CommandNotFoundException] {
    $ErrorMessage = "Function is not being executed in Azure Automation"
    throw $ErrorMessage
}

try {
    # If there is a service principal
    if ($ServicePrincipalConnection) {
        
        # Create hash table of custom parameters
        $CustomParameters = @{}
        $CustomParameters += @{
            ServicePrincipal      = $True
            TenantId              = $servicePrincipalConnection.TenantId
            ApplicationId         = $servicePrincipalConnection.ApplicationId
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
        }
        if ($AzSubscriptionId) {
            $CustomParameters += @{
                SubscriptionId = $AzSubscriptionId
            }
        }

        "`nAuthenticating with Azure Automation`n"
        $AzureConnection = Connect-AzAccount @CustomParameters
        if ($AzureConnection) {
            $AzureContext = Get-AzContext
            $AzureContext
        }
        else {
            $ErrorMessage = "Unable to authenticate with Azure."
            throw $ErrorMessage
        }
    }
    else {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
}
Catch {
    Write-Error -Message $_.exception
    throw $_.exception
}

try {

    # Check if there is a recovery plan context inserted from Azure Site Recovery
    if ($RecoveryPlanContext) {

        # Filter to just the note properties, then expand the nested property selecting the 'name', which is the VM identifier
        $VMIDs = $RecoveryPlanContext.VmMap | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

        # For each VM identifier in the array of VMs
        foreach ($VMID in $VMIDs) {
            
            # Get variable values from Azure Automation, in the format "RecoveryPlanName-VMName-ResourceType"
            # When testing failover, the VM name will be suffixed "-test", which can be used to specify test variables
            $RecoveryPlanVMResourceGroupName = Get-AzAutomationVariable `
                -AutomationAccountName $AutomationAccountName `
                -Name "$($RecoveryPlanContext.RecoveryPlanName)-$($RecoveryPlanContext.VmMap.$VMID.RoleName)-rg" `
                -ResourceGroupName $ResourceGroupName

            $RecoveryPlanVMNetworkSecurityGroupName = Get-AzAutomationVariable `
                -AutomationAccountName $AutomationAccountName `
                -Name "$($RecoveryPlanContext.RecoveryPlanName)-$($RecoveryPlanContext.VmMap.$VMID.RoleName)-nsg" `
                -ResourceGroupName $ResourceGroupName

            $RecoveryPlanVMPublicIPAddressName = Get-AzAutomationVariable `
                -AutomationAccountName $AutomationAccountName `
                -Name "$($RecoveryPlanContext.RecoveryPlanName)-$($RecoveryPlanContext.VmMap.$VMID.RoleName)-ip" `
                -ResourceGroupName $ResourceGroupName

            # If there is an automation variable for the resource group name
            if ($RecoveryPlanVMResourceGroupName) {
                
                # Get the failover Virtual Machine object
                $AzVM = Get-AzVM `
                    -ResourceGroupName $RecoveryPlanContext.VmMap.$VMID.ResourceGroupName `
                    -Name $RecoveryPlanContext.VmMap.$VMID.RoleName

                # Get the failover NIC from the VM object
                $VMNetworkInterface = Get-AzResource -ResourceId $AzVM.NetworkProfile.NetworkInterfaces.id
                $VMNetworkInterfaceObject = Get-AzNetworkInterface `
                    -Name $VMNetworkInterface.Name `
                    -ResourceGroupName $VMNetworkInterface.ResourceGroupName
                
                # Check type of failover, in case an action should be performed
                if ($RecoveryPlanContext.FailoverType -ne "Test") {
                    
                    # Create new Public IP for failover testing only
                    <#                 $PublicIPObject = New-AzPublicIpAddress `
                        -Name $AzVM.Name `
                        -ResourceGroupName $RecoveryPlanContext.VmMap.$VMID.ResourceGroupName `
                        -Location $AzVM.Location `
                        -AllocationMethod Static `
                        -Confirm:$false #>
                }
                else {

                    # If there is an automation variable, get exisiting public IP
                    if ($RecoveryPlanVMPublicIPAddressName) {
                        $PublicIPObject = Get-AzPublicIpAddress `
                            -Name $RecoveryPlanVMPublicIPAddressName.Value `
                            -ResourceGroupName $RecoveryPlanVMResourceGroupName.Value
                    }
                }

                # If there is a public IP, add to the network interface object
                If ($PublicIPObject) {
                    $VMNetworkInterfaceObject.IpConfigurations[0].PublicIpAddress = $PublicIPObject
                }

                # If there is an automation variable for the NSG, get the NSG object
                if ($RecoveryPlanVMNetworkSecurityGroupName) {
                    $NetworkSecurityGroupObject = Get-AzNetworkSecurityGroup `
                        -Name $RecoveryPlanVMNetworkSecurityGroupName.Value `
                        -ResourceGroupName $RecoveryPlanVMResourceGroupName.Value
                    
                    # Update the network interface object with the NSG
                    $VMNetworkInterfaceObject.NetworkSecurityGroup = $NetworkSecurityGroupObject
                }
                
                # Update VM network interface
                Set-AzNetworkInterface -NetworkInterface $VMNetworkInterfaceObject
            }
            else {
                $ErrorMessage = "No Azure Automation variable defined for the Resource Group Name"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
        }
    }
    else {
        $ErrorMessage = "No Recovery Plan Context from Azure Site Recovery available"
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
}
Catch {
    Write-Error -Message $_.exception
    throw $_.exception
}