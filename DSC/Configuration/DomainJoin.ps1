# DSC configuration definition
Configuration DomainJoin {
    Param(
        [Parameter(
            Mandatory = $true,
            HelpMessage="Enter the domain name"
        )]
        [string]
        $DomainName,
        [Parameter(
            Mandatory = $true,
            HelpMessage="Enter the credentials used to join to domain"
        )]
        [pscredential]
        $DomainCredential,
        [Parameter(
            Mandatory = $false,
            HelpMessage="Enter the OU name to place the computer object"
        )]
        [pscredential]
        $OU
    )

    # Import module
    Import-DscResource -ModuleName "xDSCDomainjoin"
    
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