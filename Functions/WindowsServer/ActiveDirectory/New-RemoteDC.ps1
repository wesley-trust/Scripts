<#
#Script name: New Domain Controller
#Creator: Wesley Trust
#Date: 2017-10-02
#Revision: 
#References:

.Synopsis
    Function that installs active directory, and joins to a domain on a remote computer.
.Description
    Checks if server is joined to domain, installs ADDS if not installed then promotes to domain controller.  

.Example
    New-RemoteDC -ComputerName $ComputerName -Domain $Domain
.Example
    

#>

function New-RemoteDC() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Specify a computer name, multiple computers can be in array format or comma separated",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [string[]]
        $ComputerName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential,
        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Enter the FQDN",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = "Enter the FQDN",
            ValueFromPipeLine = $true,
            ValueFromPipeLineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $DNSHostName
    )

    Begin {
        try {
            
            # If no credentials, request them
            if (!$Credential) {
                $Credential = Get-Credential -Message "Enter credential for remote computer"
            }
        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
    
    Process {
        try {

            # Split and trim input
            $ComputerName = $ComputerName.Split(",")
            $ComputerName = $ComputerName.Trim()

            # For each computer, configure service
            foreach ($Computer in $ComputerName) {
                
                # Create new session
                $Session = New-PSSession -ComputerName $Computer.dnshostname -Credential $Credential
                    
                # Run command in remote session for server
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                    
                    # Check if server is joined to the domain
                    $JoinedDomain = (Get-CimInstance -ClassName CIM_ComputerSystem).domain

                    if ($JoinedDomain -ne $Using:Domain) {
                        Write-Host "Server is not joined to $Using:Domain" -ErrorAction Stop
                    }

                    # Get domain role of server
                    $DomainRole = (Get-CimInstance -ClassName CIM_ComputerSystem).domainrole
                    
                    # Check is server is a member server of domain
                    if ($DomainRole -eq "3") {

                        # Check if ADDS is installed
                        $ADDSStatus = Get-WindowsFeature -Name "ad-domain-services"
                        
                        if ($ADDSStatus.installed -eq $True) {
                        
                            # ADDS is installed
                            Write-Host "Active Directory Domain Services are already installed"
                        }
                        else {
                            # Install ADDS
                            Write-Host "Installing Active Directory Domain Services"
                            Add-WindowsFeature -Name "ad-domain-services"
                        }

                        # Promote member server to a domain controller
                        Install-ADDSDomainController -DomainName $Using:Domain                            
                    }
                    else {
                        if ($DomainRole -ne "5") {
                            Write-Error "Server is already a domain controller" -ErrorAction Stop
                        }
                        Write-Error "Server is not a member server (or a domain controller)" -ErrorAction Stop
                    }
                }
            }
        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
    End {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
        }
    }
}