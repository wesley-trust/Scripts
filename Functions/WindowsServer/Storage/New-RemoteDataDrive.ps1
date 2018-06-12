<#
#Script name: Configure new data drive of remote computer
#Creator: Wesley Trust
#Date: 2017-08-28
#Revision: 4
#References:

.Synopsis
    Function that configures the data drive of a remote computer.
.Description
    Creates a new virtual disk in a storage space using all available disks, initialises, partitions and formats.
.Example
    New-RemoteDataDrive -ComputerName $ComputerName
.Example
    
#>
function New-RemoteDataDrive {
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
        $Credential
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
            # Storage Variables
            $Volume = "Data"
            $VirtualDisk = $Volume + "VD"
            $StoragePool = $Volume + "SP"
                        
            # Split and trim input
            $ComputerName = $ComputerName.Split(",")
            $ComputerName = $ComputerName.Trim()

            # For each computer, provision storage
            foreach ($Computer in $ComputerName) {

                # Create new session
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential
                        
                # Run command in remote session for computer
                Invoke-Command -Session $Session -ErrorAction Stop -ScriptBlock {

                    # Get Physical Disks
                    $PhysicalDisks = Get-PhysicalDisk -CanPool $True
            
                    # Create storage pool using all available physical disks
                    New-StoragePool `
                        -FriendlyName $Using:StoragePool `
                        -StorageSubsystemFriendlyName "Storage Spaces*" `
                        -PhysicalDisks $PhysicalDisks
            
                    # Create Virtual Disk in the storage pool
                    New-VirtualDisk `
                        -StoragePoolFriendlyName $Using:StoragePool `
                        -FriendlyName $Using:VirtualDisk `
                        -ResiliencySettingName Simple `
                        -UseMaximumSize `
                        -NumberOfColumns 1
            
                    # Get Virtual Disk
                    $Disk = Get-VirtualDisk -FriendlyName $Using:VirtualDisk | Get-Disk
            
                    # Initialise virtual disk
                    $Disk | Initialize-Disk
            
                    # Create partition and format volume
                    $Disk | New-Partition -UseMaximumSize -AssignDriveLetter `
                        | Format-Volume -FileSystem NTFS -NewFileSystemLabel $Using:Volume -Confirm:$False                           
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
