<#
#Script name: Get All Partner Center Customers
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 1
#References: 

.Synopsis
    Function to return Partner Center customer object.
.Description
    Query by Tenant ID, Company Name or Tenant Domain, when multiple results are returned, user is prompted to select.
.Example
    
.Example
    
#>

function Get-PCCustomerQuery() {
    [cmdletbinding()]
    Param(
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a PowerShell credential object"
        )]
        [pscredential]
        $Credential,
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a customer tenant ID"
        )]
        [string]
        $TenantID,
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a customer name"
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a customer domain name"
        )]
        [string]
        $Domain
    )

    Begin {
        try {

        # Connect to Partner Center
        Set-Location "$ENV:USERPROFILE\GitHub\Scripts\Functions\PartnerCenter\Authentication"
        . .\Connect-PartnerCenter.ps1

        Connect-PartnerCenter -Credential $Credential | Out-Null
        
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # Get customer by Id if specified
            if ($TenantID){
                $PCCustomer = Get-PCCustomer -tenantid $TenantID
            }
            else {
                # Get all customers
                $PCCustomer = Get-PCCustomer -all
                
                # If there are customers
                if ($PCCustomer){
                    # Filter by name or domain
                    if ($Name){
                        $PCCustomer = $PCCustomer | Where-Object {$_.companyprofile.companyname -like "*$Name*"}
                    }
                    elseif ($Domain){
                        $PCCustomer = $PCCustomer | Where-Object {$_.companyprofile.domain -like "*$Domain*"}
                    }

                    # Display customer details
                    if ($PCCustomer.count -gt 1){
                        $PCCustomer.companyprofile | Select-Object CompanyName,Domain,TenantID | Out-Host -Paging
                        while ($TenantID -notin $PCCustomer.id){
                            $TenantID = Read-Host "Specify Customer Tenant ID"
                        }
                        $PCCustomer = $PCCustomer | Where-Object id -EQ $TenantID
                    }
                    # Get specific customer object
                    $PCCustomer = Get-PCCustomer -tenantid $PCCustomer.id
                }
                else {
                    $ErrorMessage = "No customers returned."
                    Write-Error $ErrorMessage
                    throw $ErrorMessage
                }
            }     
        return $PCCustomer
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}