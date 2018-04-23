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
    $DirectoryRoot,
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
        # Get root directory information
        $Item = Get-Item $DirectoryRoot
        $Item = $Item | Select-Object `
            Name,`
            Parent,`
            Root,`
            FullName,`
            Length,`
            Extension,`
            Mode,`
            CreationTime,`
            CreationTimeUtc,`
            LastAccessTime,`
            LastAccessTimeUtc,`
            LastWriteTime,`
            LastWriteTimeUtc,`
            Attributes

        # Get root directory permissions
        $RootDirectoryPermissions = Get-ACL $item.FullName

        # Display access permissions for directory
        $RootDirectoryPermissions = $RootDirectoryPermissions | Select-Object Path -ExpandProperty Access | Select-Object `
            @{Label="Path";Expression={$_.Path.Replace("Microsoft.PowerShell.Core\FileSystem::","")}}, `
            @{Label="Identity";Expression={$_.IdentityReference}}, `
            @{Label="Right";Expression={$_.FileSystemRights}}, `
            @{Label="Access";Expression={$_.AccessControlType}}, `
            @{Label="Inherited";Expression={$_.IsInherited}}, `
            @{Label="Inheritance Flags";Expression={$_.InheritanceFlags}}, `
            @{Label="Propagation Flags";Expression={$_.PropagationFlags}}

        # Get childitems under root
        $ChildItems = Get-ChildItem $DirectoryRoot -Recurse
        $ChildItems = $ChildItems | Select-Object `
            Name,`
            Parent,`
            Root,`
            FullName,`
            Length,`
            Extension,`
            Mode,`
            CreationTime,`
            CreationTimeUtc,`
            LastAccessTime,`
            LastAccessTimeUtc,`
            LastWriteTime,`
            LastWriteTimeUtc,`
            Attributes

        # Get directory permissions
        $ChildItemPermissions = $ChildItems | ForEach-Object {Get-ACL $_.FullName}

        # Filter childitems to directories
        $ChildDirectories = $ChildItems | Where-Object {$_.Attributes -like "*Directory*"}

        # Get directory permissions
        $ChildDirectoryPermissions = $ChildDirectories | ForEach-Object {Get-ACL $_.FullName}

        # Display access permissions for directory
        $ChildDirectoryPermissions = $ChildDirectoryPermissions | Select-Object Path -ExpandProperty Access | Select-Object `
            @{Label="Path";Expression={$_.Path.Replace("Microsoft.PowerShell.Core\FileSystem::","")}}, `
            @{Label="Identity";Expression={$_.IdentityReference}}, `
            @{Label="Right";Expression={$_.FileSystemRights}}, `
            @{Label="Access";Expression={$_.AccessControlType}}, `
            @{Label="Inherited";Expression={$_.IsInherited}}, `
            @{Label="Inheritance Flags";Expression={$_.InheritanceFlags}}, `
            @{Label="Propagation Flags";Expression={$_.PropagationFlags}}
    
        # Export Data
        $Item | Export-CSV $CSVPath"\RootItem.csv"
        $RootDirectoryPermissions | Export-CSV $CSVPath"\RootDirectoryPermissions.csv"
        $ChildItems | Export-CSV $CSVPath"\ChildItems.csv"
        $ChildItemPermissions | Export-CSV $CSVPath"\ChildItemPermissions.csv"
        $ChildDirectoryPermissions | Export-CSV $CSVPath"\ChildDirectoryPermissions.csv"

    }
    Catch {
        Write-Error -Message $_.exception
        throw $_.exception
    }
}
End {
    
}
