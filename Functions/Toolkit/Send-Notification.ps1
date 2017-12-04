<#

#Script name: Send-Notification
#Creator: Wesley Trust
#Date: 2017-12-04
#Revision: 1
#References:

.Synopsis
    
.DESCRIPTION

#>


function Send-Notification() {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the email server username"
        )]
        [string]
        $EmailUsername,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the email server password"
        )]
        [string]
        $PlainTextPass,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the SMTP Server"
        )]
        [string]
        $SMTPServer,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the recipient email address"
        )]
        [string]
        $ToAddress,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the sender email address"
        )]
        [string]
        $FromAddress,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the subject"
        )]
        [string]
        $Subject,
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the body"
        )]
        [string]
        $Body
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
                                
            # Build Email Credential
            $EmailPassword = ConvertTo-SecureString $PlainTextPass -AsPlainText -Force
            $EmailCredential = New-Object System.Management.Automation.PSCredential ($EmailUsername, $EmailPassword)
            
            # Send email
            Send-MailMessage `
                -Credential $EmailCredential `
                -SmtpServer $SMTPServer `
                -To $ToAddress `
                -From $FromAddress `
                -Subject $Subject `
                -BodyAsHtml `
                -Body $Body
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    End {

    }
}