<#
#Script name: Get All Partner Center Customers
#Creator: Wesley Trust
#Date: 2018-04-08
#Revision: 2
#References: 

.Synopsis
    Function to return Partner Center customer object through a search query.
.Description
    Query by Company Name, Tenant Domain, or view all, when multiple results are returned, user is prompted to select.
.Example
    
.Example
    
#>
function Find-PCCustomer() {
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
            HelpMessage="Specify a customer name"
        )]
        [string]
        $Name,
        [Parameter(
            Mandatory=$false,
            Position = 0,
            HelpMessage="Specify a customer tenant domain"
        )]
        [string]
        $Domain
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception

        }
    }
    
    Process {
        try {
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
            }
        return $PCCustomer
        }
        Catch {
            Write-Error -Message $_.exception
        }
    }
    End {
        
    }
}