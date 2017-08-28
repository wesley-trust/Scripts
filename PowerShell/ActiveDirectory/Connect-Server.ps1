<#
#Script name: Connect to server
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision:
#References:

.Synopsis
    Script to test the connection to a server, then enter remote session.
.Description
    Script to test the connection to a server, then enter remote session.
.Example
    Specify server OU, in DN form, 
    Get-Servers -Domain -OU
.Example
    

#>

#Include Functions
. .\Get-DC.ps1
. .\Get-Server.ps1

#Get Credentials
$Credential = Get-Credential

#Get Servers
$ServerGroup = Get-Server

#Standard VM configuration
foreach ($Server in $ServerGroup) {
    while ($choice -notmatch "[y|n]"){
        $choice = read-host "Format data drive on $ServerGroup ? (Y/N)"
    }
    if ($choice -eq "y"){
	    $Session = New-PSSession -ComputerName $Server -Credential $Credential
        
        #Run command in remote session for servers if Y is returned as choice
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
            
            #Set permissions to drive
            


            #Reboot server
            #Restart-Computer -Force
    }
}
	else {  
        write-output 'Operation cancelled on '$Server

	    #Remove session
        Remove-pssession -session $Session
    }
}