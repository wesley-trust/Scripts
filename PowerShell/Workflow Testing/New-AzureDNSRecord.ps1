
workflow New-AzureDNSRecord {
    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the DNS Zone"
        )]
        [string]
        $DNSZone = "test2.local",
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the record name"
        )]
        [string]
        $RecordName = "@",
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the record type"
        )]
        [string]
        $RecordType = "TXT",
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the record value"
        )]
        [string]
        $Value = "Wes",
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="Enter the time to live for the record"
        )]
        [string]
        $TTL = "300",
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the location for the DNS Zone resource group"
        )]
        [string]
        $Location
    )
    
    try {
        try {
            # Get DNS Zone
            $DNSZoneObject = Get-AzureRmResourceGroup | Where-Object ResourceID -EQ $DNSZone | Get-AzureRmDnsZone

            # If no zone exists
            if (!$DNSZoneObject){
                
                # If no location for the zone is specified
                if (!$Location){
                    
                    # Get available locations
                    Get-AzureRmLocation | Select-Object Location
                    
                    # Prompt for location
                    $Location = Read-Host "Enter resource location (recommended: uksouth)"
                }
                # Create resource group
                $ResourceGroupName = $DNSZone
                New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
                
                # Create DNZ Zone
                $DNSZoneObject = New-AzureRmDnsZone -Name $DNSZone -ResourceGroupName $ResourceGroupName

                Write-Host "DNS Zone created"
            }
            Else {
                Write-Host "DNS Zone exists"
            }
            return $DNSZoneObject
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }

        # DNS Record Set
        try {
            
            # Get DNS record set
            $DNSRecordSetObject = $DNSZoneObject | Get-AzureRmDnsRecordSet | Where-Object {$_.Name -eq $RecordName -and $_.recordtype -eq $RecordType}

            # If doesn't exist
            if (!$DNSRecordSetObject){
                
                # Create DNS record set
                $DNSRecordSetObject = $DNSZone | New-AzureRmDnsRecordSet -Name $RecordName -RecordType $RecordType -Ttl $TTL

                Write-Host "DNS record set created"
            }
            Else {
                Write-Host "DNS record set exists"
            }
            return $DNSRecordSetObject
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }

        # Add new record config
        $DNSRecordSet | Add-AzureRmDnsRecordConfig -Value $Value
    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}