<#
#Script name: Get disk space in GB
#Creator: Wesley Trust
#Date: 2018-06-05
#Revision: 1

.Synopsis
    Script that calls function to get disk space across multiple computers.
.Description
    Supports multiple computers with pipeline input by property name, an array or comma separated list
.Example
    Get-DiskSpaceInGB -ComputerName $ComputerNames

#>

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
        # Function definitions
        $FunctionLocation = "$ENV:USERPROFILE\GitHub\Scripts\Functions"
        $Functions = @(
            "$FunctionLocation\WindowsServer\Storage\Get-DiskSpaceInGB.ps1"
        )

        # Function dot source
        foreach ($Function in $Functions) {
            . $Function
        }
    }
    catch {
        Write-Error -Message $_.Exception
    }      
}
process {
    try {
            
        # Call function with array
        $ComputerDiskSpace = Get-DiskSpaceInGB -ComputerName $ComputerNames

        # Format results
        $ComputerDiskSpace | Format-Table DriveLetter, SizeInGB, FreeSpaceInGB -GroupBy ComputerName
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