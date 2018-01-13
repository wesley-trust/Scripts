# DSC configuration definition
Configuration DotNet35 {
    Param(
        [Parameter(
            Mandatory=$false,
            HelpMessage="Enter the feature name"
        )]
        [string]
        $FeatureName = "NET-Framework-Features"
    )

    # Import module
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    # Node configuration
    Node RequiresFW35 {
        # Features
        WindowsFeature DotNetFW35Install {
            Name = $FeatureName
            Ensure = "Present"
        }
    }
}