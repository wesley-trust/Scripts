<#
#Script name: Get All Partner Center Customers
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 1
#References: 

.Synopsis
    Function to display all customer names and tenant IDs
.Description

.Example
    
.Example
    
#>

function Get-PCCustomerAll() {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a PowerShell credential object"
        )]
        [pscredential]
        $Credential
    )

    Begin {
        try {

        # Connect to Partner Center
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Authentication"
        . .\Connect-PartnerCenter.ps1

        Connect-PartnerCenter -Credential $Credential
        
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {

            # Get all Partner Center customers
            $PCCustomers = Get-PCCustomer -all

            # Display list of names and tenant IDs
            $PCCustomers.companyprofile | Select-Object CompanyName,TenantID | Out-Host -Paging

        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}