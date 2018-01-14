# DSC configuration definition
Configuration DomainJoin {
    Param(
        [Parameter(
            Mandatory = $false,
            HelpMessage="Enter the domain name"
        )]
        [string]
        $DomainName,
        [Parameter(
            Mandatory = $false,
            HelpMessage="Enter the credentials used to join to domain"
        )]
        [pscredential]
        $DomainCredential,
        [Parameter(
            Mandatory = $false,
            HelpMessage="Enter the name of the OU to place the computer object (in DN notation)"
        )]
        [string]
        $OU
    )

    # Import modules
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName "xDSCDomainjoin"

    # Automation Variables
    if (!$DomainName){
        $DomainName = Get-AzureRmAutomationVariable -Name "DomainName"
    }
    if (!$DomainCredential){
        $DomainCredential = Get-AzureRmAutomationCredential -Name "DomainCredential"
    }

    # Node configuration
    Node RequireDomainJoin {
        # Join to domain
        xDSCDomainjoin DomainPresent {
            Domain = $DomainName
            Credential = $DomainCredential
            JoinOU = $OU
        }
    }
}