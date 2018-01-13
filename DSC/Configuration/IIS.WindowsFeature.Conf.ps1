# DSC configuration definition
Configuration WebServer {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the feature name"
        )]
        [string]
        $FeatureName = "Web-Server"
    )

    # Import module
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    # Node configuration
    Node RequiresIIS {
        # Features
        WindowsFeature WebServerRoles {
            Name = $FeatureName
            Ensure = "Present"
        }
    }
}