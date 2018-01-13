# DSC configuration definition
Configuration RSAT {
    
    # Import module
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    Node RequiresRSAT {
        WindowsFeature MyFeatureInstance {
            Ensure = "Present"
            Name =  "RSAT"
        }
    }
}