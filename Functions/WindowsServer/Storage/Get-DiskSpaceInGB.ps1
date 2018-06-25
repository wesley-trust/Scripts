<#
#Script name: Get disk space in GB
#Creator: Wesley Trust
#Date: 2018-06-05
#Revision: 1

.Synopsis
    Function to get disk space across multiple computers.
.Description
    Supports multiple computers with pipeline input by property name, an array or comma separated list
.Example
    Get-DiskSpaceInGB -ComputerName $ComputerNames

#>
function Get-DiskSpaceInGB {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = "Specify a Computer name, supporting an array or comma separated list",
            ValueFromPipeLineByPropertyName = $true
        )]
        [Alias("hostname")]
        [string[]]
        $ComputerName
    )
    begin {
        try {

        }
        catch {
            
            Write-Error -Message $_.Exception
        }

    }
    process {
        try {

            # Split and trim input
            $ComputerName = $ComputerName.Split(",")
            $ComputerName = $ComputerName.Trim()

            # Get diskspace for each computer
            $DiskSpace = foreach ($Computer in $ComputerName) {
                $ComputerLogicalDisk = Get-CimInstance -ComputerName $Computer `
                    -ClassName Win32_logicaldisk
    
                # Create custom object with property values converted to GB
                foreach ($LogicalDisk in $ComputerLogicalDisk) {
                    [PSCustomObject]@{
                        ComputerName  = $Computer;
                        DriveLetter   = $LogicalDisk.name;
                        SizeInGB      = $LogicalDisk.Size / 1GB -as [int];
                        FreeSpaceInGB = $LogicalDisk.freespace / 1GB -as [int]
                    }
                }
            }

            return $DiskSpace
        }
        catch {

            Write-Error -Message $_.Exception
        }

        
    }
    end {
        try {

        }
        catch {

            Write-Error -Message $_.Exception
        }
    }
}