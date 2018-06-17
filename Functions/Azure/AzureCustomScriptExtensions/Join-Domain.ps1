<#
#Script name: Join Domain
#Creator: Wesley Trust
#Date: 2017-10-21
#Revision: 1
#References:

.Synopsis
    Function to join computer to domain
.Description
    
.Example

.Example

#>

function Join-Domain() {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specif domain for computer to join"
        )]
        [string]
        $Domain,
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify domain username"
        )]
        [string]
        $Username,
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify domain password"
        )]
        [string]
        $PlainTextPass
    )

    Begin {
        try {

        }
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    
    Process {
        try {
            
            # Convert password to secure string
            $Password = ConvertTo-SecureString $PlainTextPass -AsPlainText -Force
            
            # Create credentials object
            $DomainCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

            # Add computer to domain and restart
            Add-Computer -DomainName $Domain -Credential $DomainCredentials -Force -Restart
        }
        Catch {
            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
    End {
        try {

        }
        Catch {

            Write-Error -Message $_.exception
            throw $_.exception
        }
    }
}