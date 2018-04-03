<#
#Script name: Get Exchange Information
#Creator: Wesley Trust
#Date: 2018-03-29
#Revision: 2
#References: 

.Synopsis
    Functions to get Exchange information
.Description
    Supports output to screen or export to CSV
.Example
    Get-ExchangeDirectoryInfo -CSVPath "$Home\Documents\ExchangeInfo"
.Example
    Get-ExchangeOrganisationInfo -CSVPath "$Home\Documents\ExchangeInfo"
.Example
    Get-ExchangeMailboxInfo -CSVPath "$Home\Documents\ExchangeInfo"
#>

function Get-ExchangeDirectoryInfo() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify path for CSV export"
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
            # Check if CSVPath exists
            $PathExists = Test-Path -Path $CSVPath
            if (!$PathExists){
                $PathExists = New-item -ItemType Directory -Path $CSVPath
            }

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
            $Output = foreach ($Command in $Commands){
                &$Command
            }
            
            # Filter Output
            $Output = $Output | Select-Object Name,Server,InternalURL,ExternalURL,MRSProxyEnabled
            
            # If a CSV path exists, export to CSV
            if ($CSVPath){
                $Output | Export-CSV $CSVPath"\VirtualDirectories.csv"
            }
            else {
                $Output
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}

function Get-ExchangeOrganisationInfo() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify path for CSV export"
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
            # Check if CSVPath exists
            $PathExists = Test-Path -Path $CSVPath
            if (!$PathExists){
                $PathExists = New-item -ItemType Directory -Path $CSVPath
            }

            # Exchange Organisation commands
            $Commands = @(
                "Get-ExchangeCertificate",
                "Get-OrganizationConfig",
                "Get-ClientAccessServer",
                "Get-ExchangeServer",
                "Get-AcceptedDomain",
                "Get-RemoteDomain"
            )

            # Execute each command and output to variable
            foreach ($Command in $Commands){
                $Output = &$Command
                
                # If a CSV path exists, export to CSV
                if ($CSVPath){
                    $Output | Export-CSV $CSVPath"\"$Command".csv"
                }
                else {
                    $Output
                }
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}

function Get-ExchangeMailboxInfo() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify path for CSV export"
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
            # Check if CSVPath exists
            $PathExists = Test-Path -Path $CSVPath
            if (!$PathExists){
                $PathExists = New-item -ItemType Directory -Path $CSVPath
            }

            # Exchange Mailbox commands
            $Commands = @(
                "Get-MailboxStatistics",
                "Get-MailboxFolderStatistics"
            )
            
            # Get Mailboxes
            $Mailboxes = Get-Mailbox -ResultSize unlimited
            $Mailboxes | Export-CSV $CSVPath"\Get-Mailbox.csv"
            
            # Execute each command and output to variable
            foreach ($Command in $Commands){
                $Output = $Mailboxes | &$Command
                
                # If a CSV path exists, export to CSV
                if ($CSVPath){
                    $Output | Export-CSV $CSVPath"\"$Command".csv"
                }
                else {
                    $Output
                }
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
function Get-ExchangePublicFolderInfo() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify path for CSV export"
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
            # Check if CSVPath exists
            $PathExists = Test-Path -Path $CSVPath
            if (!$PathExists){
                $PathExists = New-item -ItemType Directory -Path $CSVPath
            }
            
            # Get Public Folders
            $Output = Get-PublicFolder -ErrorAction SilentlyContinue

            if (!$Output){
                $Output = "No public folder databases"
            }
            
            # If a CSV path exists, export to CSV
            if ($CSVPath){
                $Output | Export-CSV $CSVPath"\Get-PublicFolder.csv"
            }
            else {
                $Output
            }
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        
    }
}
