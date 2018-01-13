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
        WindowsFeature WebServerRole {
            Name = $FeatureName
            Ensure = "Present"
        }
        WindowsFeature ASPNET45 {
            Name = "Web-Asp-Net45"
            Ensure = "Present"
        }
    }
}