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

    # Check if there is a recovery plan context
    if ($RecoveryPlanContext) {

        # Filter to just the note properties and expand the nested property, which is the VMID
        $VMIDs = $RecoveryPlanContext.VmMap | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

        # For each VM identifier in the array of VMs
        foreach ($VMID in $VMIDs) {

            # Get variable values from Azure Automation
            $RecoveryPlanVMResourceGroupName = Get-AzAutomationVariable `
                -AutomationAccountName $ConnectionName `
                -Name ($RecoveryPlanContext.RecoveryPlanName+"-"+$RecoveryPlanContext.VmMap.$VMID.RoleName+"-rg") `
                -ResourceGroupName $ResourceGroupName

            $RecoveryPlanVMNetworkSecurityGroupName = Get-AzAutomationVariable `
                -AutomationAccountName $ConnectionName `
                -Name ($RecoveryPlanContext.RecoveryPlanName+"-"+$RecoveryPlanContext.VmMap.$VMID.RoleName+"-nsg") `
                -ResourceGroupName $ResourceGroupName

            $RecoveryPlanVMPublicIPAddressName = Get-AzAutomationVariable `
                -AutomationAccountName $ConnectionName `
                -Name ($RecoveryPlanContext.RecoveryPlanName+"-"+$RecoveryPlanContext.VmMap.$VMID.RoleName+"-ip") `
                -ResourceGroupName $ResourceGroupName

            # Get Virtual Machine
            $AzVM = Get-AzVM `
                -ResourceGroupName $RecoveryPlanContext.VmMap.$VMID.ResourceGroupName `
                -Name $RecoveryPlanContext.VmMap.$VMID.RoleName

            # Get NIC for VM
            $VMNetworkInterface = Get-AzResource -ResourceId $AzVM.NetworkProfile.NetworkInterfaces.id

            $VMNetworkInterfaceObject = Get-AzNetworkInterface `
                -Name ($VMNetworkInterface.Name) `
                -ResourceGroupName ($VMNetworkInterface.ResourceGroupName)
            
            # Check type of failover
            if ($RecoveryPlanContext.FailoverType -ne "Test") {
                
                # Create new Public IP
                <#                 $PublicIPObject = New-AzPublicIpAddress `
                    -Name $AzVM.Name `
                    -ResourceGroupName $RecoveryPlanContext.VmMap.$VMID.ResourceGroupName `
                    -Location $AzVM.Location `
                    -AllocationMethod Static `
                    -Confirm:$false #>
            }
            else {
                $PublicIPObject = Get-AzPublicIpAddress `
                    -Name $RecoveryPlanVMPublicIPAddressName.Value `
                    -ResourceGroupName $RecoveryPlanContext.VmMap.$VMID.ResourceGroupName
            }

            # If there is a public IP, add to object
            If ($PublicIPObject) {
                $VMNetworkInterfaceObject.IpConfigurations[0].PublicIpAddress = $PublicIPObject
            }
            
            # If there are NSG values, add to object
            if ($RecoveryPlanVMNetworkSecurityGroupName.Value -And $RecoveryPlanVMResourceGroupName.Value) {
                $NetworkSecurityGroupObject = Get-AzNetworkSecurityGroup `
                    -Name $RecoveryPlanVMNetworkSecurityGroupName.Value `
                    -ResourceGroupName $RecoveryPlanVMResourceGroupName.Value
                
                # Update object
                $VMNetworkInterfaceObject.NetworkSecurityGroup = $NetworkSecurityGroupObject
            }
            
            # Update VM network interface
            Set-AzNetworkInterface -NetworkInterface $VMNetworkInterfaceObject
        }
    }
    else {
        $ErrorMessage = "No recovery plan object"
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
}
Catch {
    Write-Error -Message $_.exception
    throw $_.exception
}