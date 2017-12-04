<#
#Script name: Stop-VM
#Creator: Wesley Trust
#Date: 2017-10-10
#Revision: 3
#References:
.Synopsis
    A script that gets Azure VMs within a resource group, and stops them.
.DESCRIPTION
    A script that gets Azure VMs within a resource group, and stops them,
    when no VMs are specified, all VMs within the resource group are used.
#>

Function Stop-VM(){
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
        $VMNames
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
                $ErrorMessage = "No VMs to stop"
                Write-Error $ErrorMessage
                throw $ErrorMessage
            }
            
            foreach ($VMName in $VMNames){
                $VMObject = Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Status -Name $VMName
                
                #Get status
                $VMObject = $VMObject | Where-Object {($_.Statuses)[1].DisplayStatus -like "*running*"}
            
                #Stop VM
                Write-Host "Stopping VM:$VMName"
                $VMObject | Stop-AzureRmVM -Force
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