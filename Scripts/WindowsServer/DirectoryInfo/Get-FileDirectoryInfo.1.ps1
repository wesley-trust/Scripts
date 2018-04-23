<#
#Script name: Get File Directory Information
#Creator: Wesley Trust
#Date: 2018-04-12
#Revision: 1
#References: 

.Synopsis
    
.Description

.Example
    
.Example
    
#>

Param(
    [Parameter(
        Mandatory=$true,
        Position = 0
    )]
    [string]
    $DirectoryRoot = "C:\Users\wtrust\Downloads\test",
    [Parameter(
        Mandatory=$false,
        HelpMessage="Specify path for CSV export"
    )]
    [string]
    $CSVPath = "$home\Documents\FileDirectoryInfo"
)

Begin {
    try {
        # Check if CSVPath exists
        $PathExists = Test-Path -Path $CSVPath
        if (!$PathExists){
            $PathExists = New-item -ItemType Directory -Path $CSVPath
        }
    }
    catch {
        Write-Error -Message $_.Exception
        throw $_.exception
    }
}

Process {
    try {
        
        # Get childitems under root
        Get-ChildItem $DirectoryRoot -Recurse


        # Get directory permissions
        $ChildItemPermissions = $ChildItems | ForEach-Object {Get-ACL $_.FullName}

        

    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}
