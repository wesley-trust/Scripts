<#
#Script name: New Domain Controller
#Creator: Wesley Trust
#Date: 2017-10-02
#Revision: 
#References:

.Synopsis
    Script that calls a function that installs active directory, and joins to a domain.
.Description
    Checks if server is joined to domain, installs ADDS if not installed then promotes to domain controller.  

.Example
    New-DC -Domain $Domain -DNSHostName $Server
.Example
    

#>

#Include Functions
. .\Test-Server.ps1

function New-DC() {
    #Parameters
    Param(
        #Request Domain
        [Parameter(
            Mandatory=$false,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request DNS Host name of server
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DNSHostName)

    Begin {
        
        #If there are no credentials, prompt for credentials
        if ($Credential -eq $null) {
            Write-Output "Enter credentials for remote computer"
            $Credential = Get-Credential
        }
    }
    
    Process {

        #Reconstitute object from pipeline
        $ServerGroup = foreach ($Server in $_){
            $ObjectProperties = @{
                DNSHostName  = $Server.DNSHostName
                Status  = $Server.Status
            }
            New-Object psobject -Property $ObjectProperties
        }

        #If there are no statuses for servers
        if (!$Server.Status){

            #If there are no servers at all in array, get servers that can successfully be connected to
            if (!$ServerGroup){
                
                #If there aren't any servers, and no domain and OU are specified, get successful servers
                If (!$Domain -or !$ou){
                    $ServerSuccessGroup = Get-SuccessServer
                }
                else {
                    #Get successful servers and pass parameters
                    $ServerSuccessGroup = Get-SuccessServer -Domain $Domain -OU $OU
                }
            }
            Else {
                
                #Pipe the servers to test and get successful ones
                $ServerSuccessGroup = $ServerGroup | Test-Server | Get-SuccessServer
            }
        }
        
            #Display the servers returned for confirmation
            Write-Host ""
            Write-Host "Successfully connected to:"
            Write-Host ""
            Write-Output $ServerSuccessGroup.DNSHostName
            Write-Host ""
    
        #Prompt for input
        while ($choice -notmatch "[y|n]"){
            $choice = read-host "Install ADDS and promote member server to domain controller? (Y/N)"
        }
        
        #Execute command
        if ($choice -eq "y"){
            Write-Host ""
            Write-Output "Configuring new domain controller for domain $Domain"
            Write-Output ""
            foreach ($Server in $ServerSuccessGroup) {
                
                #Create new session
                $Session = New-PSSession -ComputerName $Server.dnshostname -Credential $Credential
                    
                #Run command in remote session for server
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                    
                    #Check if server is joined to the domain
                    $JoinedDomain = (Get-CimInstance -ClassName CIM_ComputerSystem).domain

                    if ($JoinedDomain -ne $Using:Domain){
                        Write-Host "Server is not joined to $Using:Domain" -ErrorAction Stop
                    }

                    #Get domain role of server
                    $DomainRole = (Get-CimInstance -ClassName CIM_ComputerSystem).domainrole
                    
                    #Check is server is a member server of domain
                    if ($DomainRole -eq "3"){

                        #Check if ADDS is installed
                        $ADDSStatus = Get-WindowsFeature -Name "ad-domain-services"
                        
                        if ($ADDSStatus.installed -eq $True){
                            #ADDS is installed
                            Write-Host "Active Directory Domain Services are already installed"
                        }
                        Else {
                            #Install ADDS
                            Write-Host "Installing Active Directory Domain Services"
                            Add-WindowsFeature -Name "ad-domain-services"
                        }

                        #Promote member server to a domain controller
                        Install-ADDSDomainController -DomainName $Using:Domain                            
                    }
                    Else {
                        if ($DomainRole -ne "5"){
                            Write-Error "Server is already a domain controller" -ErrorAction Stop
                        }
                        Write-Error "Server is not a member server (or a domain controller)" -ErrorAction Stop
                    }
                }
            }
            else {  
                Write-Host ""
                write-Error "Operation cancelled" -ErrorAction Stop
                Write-Host ""
            }
        }
    }
    End {
        
    }
}