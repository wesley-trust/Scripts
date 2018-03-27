# Script Name: Create or update MAPI IP restriction
# Author: Wesley Trust
# Revision: 1
# Date: 2018-03-23

## Variables
$CASRuleName = "Block MAPI except from Trusted IPs"
# Array of trusted IPs
$TrustedIPs = @(
    "",
    "",
    "",
    "",
    ""
)
$Force = $true

try {

    # If force is true, create hashtable of custom parameters
    if ($Force){
    
        # Set confirmation property to false
        $CustomParameters = @{
            Confirm = $false
        }
    }

    # Check for existing CAS rule
    $CASRule = Get-ClientAccessRule -Identity $CASRuleName -ErrorAction SilentlyContinue

    # If CAS rule exists
    if ($CASRule){
                
        # Remove exisiting rule
        $CASRule | Remove-ClientAccessRule @CustomParameters
    }

    # Create new CAS rule
    New-ClientAccessRule `
        -Name $CASRuleName `
        -Action DenyAccess `
        -AnyOfProtocols OutlookAnywhere `
        -Scope All `
        -ExceptAnyOfClientIPAddressesOrRanges $TrustedIPs `
        @CustomParameters
}
catch {
    Write-Error -Message $_.exception
    throw $_.exception
}