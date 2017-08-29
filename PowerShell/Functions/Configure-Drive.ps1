<#
#Script name: Configure data drives
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 2
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

function Configure-Drive () {
    #Parameters
    Param(
        #Request Domain
        [Parameter(
            Mandatory=$True,
            Position=1,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        
        #Request OU
        [Parameter(
            Mandatory=$True,
            Position=2,
            HelpMessage="Enter the FQDN",
            ValueFromPipeLine=$true,
            ValueFromPipeLineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OU)
    
    #Storage
    $Volume = "Data"
    $VirtualDisk = $Volume+"VD"
    $StoragePool = $Volume+"SP"

    #If there are no credentials, prompt for credentials
    if ($Credential -eq $null) {
        Write-Output "Enter credentials for remote computer"
        $Credential = Get-Credential
    }
    
    #Get Servers
    $ServerGroup = Test-Server -Domain $Domain -OU $OU
    
    #Check server name(s) returned
    if ($ServerGroup -eq $null){
        Write-Host ""
        Write-Error 'No servers returned.' -ErrorAction Stop
    }

    #Add successfully connected servers to variable
    $ServerSuccessGroup = $ServerGroup | Where-Object -Property Status -eq "Success"
    #Add failed to connect servers to variable
    $ServerFailGroup = $ServerGroup | Where-Object -Property Status -eq "Fail"
    
    #Check whether no servers are successful.
    If ($ServerSuccessGroup -eq $null){
        Write-Error "Unable to connect to any servers." -ErrorAction Stop
    }

    #Display host message for successfully connected servers.
    Write-Host ""
    Write-Host "Successfully connected to:"
    Write-Host ""
    Write-Output $ServerSuccessGroup.name
    Write-Host ""

    #Check if there are any servers that failed.
    If ($ServerFailGroup -eq $null){
    }
    #If there are servers that failed, display a host message.
    Else {
        Write-Host "Failed to connect to:"
        Write-Host ""
        Write-Output $ServerFailGroup.name
        Write-Host ""
    }
    
    #Prompt for input
    while ($choice -notmatch "[y|n]"){
        $choice = read-host "Configure the data drives on servers that are accessible? (Y/N)"
    }
    
    #Execute command
    if ($choice -eq "y"){
        Write-Host ""
        Write-Output "Configuring drives on remote computers."
        Write-Output ""
        foreach ($Server in $ServerSuccessGroup) {
                $Session = New-PSSession -ComputerName $Server.name -Credential $Credential
                
                #Run command in remote session for servers
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
                    
                    #Set permissions to drive
                    
            }
        }
    }
	else {  
        Write-Host ""
        write-Error "Operation cancelled"
        Write-Host ""
    }
}