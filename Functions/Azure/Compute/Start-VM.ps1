<#
#Script name: Start-VM
#Creator: Wesley Trust
#Date: 2017-10-10
#Revision: 3
#References:
.Synopsis
    A script that gets Azure VMs within a resource group, starts them or restarts if running and parameter set.
.DESCRIPTION
    A script that gets Azure VMs within a resource group, starts them or restarts if running and parameter set.
    When no VMs are specified, all VMs within the resource group are used.
#>

Function Start-VM(){
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
            Mandatory=$false,
            HelpMessage="If true, started VMs will be restarted."
        )]
        [bool]
        $RestartRunningVM = $false
    )
    Begin {
        try {
            # Load functions
            Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\Azure\Authentication\"
            . .\Connect-AzureRM.ps1
            
            # Connect to Azure
            Connect-AzureRM -SubscriptionID $SubscriptionID

            # Update subscription Id from Azure Connection
            $SubscriptionID = $AzureConnection.Subscription.id
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
                $ErrorMessage = "No VMs to start"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }

            # Process
            foreach ($VMName in $VMNames){

                # Get VM objects
                $VMObject = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Status -Name $VMName
                
                # Get status
                $VMObjectStopped = $VMObject | Where-Object {($_.Statuses)[1].DisplayStatus -like "*deallocated*"}
                
                # Start VM
                Write-Host "Starting VM:$VMName"
                $VMObjectStopped | Start-AzureRmVM

                # If variable is true, get running VMs and restart.
                if ($RestartRunningVM){
                    # Get status
                    $VMObjectStarted = $VMObject | Where-Object {($_.Statuses)[1].DisplayStatus -like "*running*"}
                    
                    # Restart VM
                    Write-Host "Restarting VM:$VMName"
                    $VMObjectStarted | Restart-AzureRmVM
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