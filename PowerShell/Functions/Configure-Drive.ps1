<#
#Script name: Configure data drives
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 3
#References:

.Synopsis
    Script that calls a function that tests servers, within an OU, can be connected to remotely, and configures their data drives.
.Description
    Script that calls a function that tests servers, within an OU, can be connected to remotely, and configures their data drives,
    creating a storage space, virtual disk and partition, using all suitable disks.
.Example
    Specify the fully qualified Domain Name (FQDN) and Organisational Unit (OU) by distinguished name (DN).
    Configure-Drive -Domain $Domain -OU $OU
.Example
    

#>

#Include Functions
. .\Test-Server.ps1

function Configure-Drive() {
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
        
        #Request OU
        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter in DN format",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU,
        
        #Server Host name
        [Parameter(
            Mandatory=$false,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DNSHostName,
        
        #Server status
        [Parameter(
            Mandatory=$false,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Status)

    Begin {
    
        #Function Variables
        #Storage
        $Volume = "Data"
        $VirtualDisk = $Volume+"VD"
        $StoragePool = $Volume+"SP"
    
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
            $choice = read-host "Configure data drive? (Y/N)"
        }
        
        #Execute command
        if ($choice -eq "y"){
            Write-Host ""
            Write-Output "Configuring drives on remote computers."
            Write-Output ""
            foreach ($Server in $ServerSuccessGroup) {
                
                #Temp commenting out action section, whilst troubleshooting pipeline process
                Write-Host ""
                Write-Host "TEST: Successfully configured data drives on"$Server.DNSHostName
                Write-Host ""

                <# #Create new session
                $Session = New-PSSession -ComputerName $Server.name -Credential $Credential
                    
                #Run command in remote session for server
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {
                    
                    #Provision storage
                    #Get Physical Disks
                    $PhysicalDisks = (Get-PhysicalDisk -CanPool $True)
        
                    #Create storage pool using all available physical disks
                    New-StoragePool -FriendlyName $Using:StoragePool -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $PhysicalDisks
        
                    #Create Virtual Disk in the storage pool
                    New-VirtualDisk -StoragePoolFriendlyName $Using:StoragePool -FriendlyName $Using:VirtualDisk -ResiliencySettingName Simple -UseMaximumSize -NumberOfColumns 1
        
                    #Get Virtual Disk
                    $Disk = (Get-VirtualDisk -FriendlyName $Using:VirtualDisk | Get-Disk)
        
                    #Initialise virtual disk
                    $Disk | Initialize-Disk
        
                    #Create partition and format volume
                    $Disk | New-Partition -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel $Using:Volume -Confirm:$False
                    
                    #Successfully configured data drives
                    Write-Host ""
                    Write-Host "Successfully configured data drives on "$Server.name
                    Write-Host ""
                        
                } #>
            }
        }
        else {  
            Write-Host ""
            write-Error "Operation cancelled" -ErrorAction Stop
            Write-Host ""
        }
    }
    End {
        
    }
}
