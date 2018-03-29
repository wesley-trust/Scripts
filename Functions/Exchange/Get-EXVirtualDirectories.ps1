<#
#Script name: Get Exchange Virtual Directory information
#Creator: Wesley Trust
#Date: 2018-03-29
#Revision: 1
#References: 

.Synopsis
    Function to get Exchange virtual directories
.Description
    Supports output to screen and export to CSV
.Example
    Get-EXVirtualDirectories
.Example
    Get-EXVirtualDirectories -CSVPath "$Home\Documents\VirtualDirectoriesInfo.csv"
#>

function Get-EXVirtualDirectories() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify path and filename for CSV export"
        )]
        [string]
        $CSVPath
    )

    Begin {
        try {

        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            # Exchange Virtual Directory commands
            $Commands = @(
                "Get-ActiveSyncVirtualDirectory",
                "Get-AutodiscoverVirtualDirectory",
                "Get-EcpVirtualDirectory",
                "Get-OabVirtualDirectory",
                "Get-OwaVirtualDirectory",
                "Get-WebServicesVirtualDirectory"
            )
            
            # Execute each command and output to variable
            $VirtualDirectories = foreach ($Command in $Commands){
                &$Command
            }
            
            # If a CSV path exists, export to CSV
            if ($CSVPath){
                $VirtualDirectories | Export-CSV $CSVPath
            }
            
            # Output to pipeline
            $VirtualDirectories | Format-List Name,Server,InternalURL,ExternalURL,MRSProxyEnabled

        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}