<#
#Script name: Resize-VM
#Creator: Wesley Trust
#Date: 2017-10-10
#Revision: 3
#References: 

.Synopsis
    A script that gets Azure VMs within a resource group, and resizes them.
.DESCRIPTION
    A script that gets Azure VMs within a resource group, and resizes them,
    when no VMs are specified, all VMs within the resource group are used,
    includes error checking for valid VM size and supported location,
    attempts to deallocate VM when size is unsupported.
#>

Function Resize-VM(){
    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the resource group that all VMs belong to"
        )]
        [string]
        $ResourceGroupName,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter VM names"
        )]
        [string[]]
        $VMNames,
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter VM size"
        )]
        [string]
        $VMSize,
        [Parameter(
            Mandatory=$true,
            HelpMessage="Deallocate VM if size is not available for VM"
        )]
        [bool]
        $DeallocateIfRequired = $False
    )

    Begin {
        try {
            # Load functions
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\"
            . .\Connect-AzureRM.ps1
            
            # Connect to Azure
            Connect-AzureRM -SubscriptionID $SubscriptionID
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    Process {
        try {
            
            # Get the resource group to check it exists, store in variable, if not catch exception
            $ResourceGroup = Get-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName

            # If no VMs are specified in the parameter, get Get VM names from resource group
            if (!$VMNames){
                $VMObjects = $ResourceGroup | Get-AzureRmVM
                $VMNames = ($VMObjects).Name
            }
            
            # If there are still no VMs, throw exception
            if (!$VMNames){
                $ErrorMessage = "No VMs to resize"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            foreach ($VMName in $VMNames){
                
                # Get VM Object
                $VMObject = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $VMName

                # If the VM is not already the intended size
                if ($VMObject.HardwareProfile.VmSize -ne $VMSize){

                    # Get supported sizes in location of VM
                    $SupportedVMSize = Get-AzureRmVMSize -Location $VMObject.Location

                    # Invalid size
                    if ($SupportedVMSize.name -notcontains $VMSize){
                        $ErrorMessage = "VM size is invalid or not available in that location."
                        Write-Error -Message $ErrorMessage
                        throw $ErrorMessage
                    }

                    # Get supported sizes for VM
                    $SupportedVMSize = Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $VMName

                    # If the VM size is not supported
                    if ($SupportedVMSize.name -notcontains $VMSize){

                        # Get running status
                        $VMStatus = $VMObject | Where-Object {($_.Statuses)[1].DisplayStatus -like "*running*"}

                        # If the VM is running
                        if ($DeallocateIfRequired){
                            if ($VMStatus){

                                # Deallocated VM
                                Write-Host "Stopping VM:$VMName"
                                $VMObject | Stop-AzureRmVM -Force

                                # Get new supported sizes for VM
                                $SupportedVMSize = Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $VMName

                                # If the VM size is still not supported
                                if ($SupportedVMSize.name -notcontains $VMSize){
                                
                                    # Restart VM
                                    Write-Host "Starting VM:$VMName"
                                    $VMObject | Start-AzureRmVM
                                }          
                            }
                        }

                        # Unsupported size
                        $ErrorMessage = "VM size is not supported for this VM."
                        Write-Error -Message $ErrorMessage
                        throw $ErrorMessage
                    }
                            
                    # Set new VM size
                    $VMObject.HardwareProfile.VmSize = $VMSize

                    # Update VM
                    Write-Host "Updating VM:$VMName"
                    Update-AzureRmVM -VM $VMObject -ResourceGroupName $ResourceGroupName
                }
                Else {
                    $ErrorMessage = "VM cannot be resized as it is already the intended size."
                    Write-Error -Message $ErrorMessage
                    throw $ErrorMessage
                }      
            }
        }
        Catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    End {

    }
}