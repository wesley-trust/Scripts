<#
#Script name: Get disk space in GB
#Creator: Wesley Trust
#Date: 2018-06-05
#Revision: 1

.Synopsis
    Script that calls a function to get disk space across multiple computers and formats for display
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
    }
    process {
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
                    DriveLetter   = $_.name;
                    SizeInGB      = $_.Size / 1GB -as [int];
                    FreeSpaceInGB = $_.freespace / 1GB -as [int]
                }
            }
        }
        # Return Output
        return $DiskSpace
    }
    end {
    }
}
# Example array of computer names
$ComputerNames = @(
    "ComputerName1",
    "ComputerName2"
)
# Call function with array
$ComputerDiskSpace = Get-DiskSpaceInGB -ComputerName $ComputerNames
# Format results
$ComputerDiskSpace | Format-Table DriveLetter, SizeInGB, FreeSpaceInGB -GroupBy ComputerName
