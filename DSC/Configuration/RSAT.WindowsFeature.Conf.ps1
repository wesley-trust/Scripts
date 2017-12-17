# Import module
Import-DscResource –ModuleName 'PSDesiredStateConfiguration'

# Configuration definition
Configuration RSAT {

    Node RequiresRSAT {
        WindowsFeature MyFeatureInstance {
            Ensure = "Present"
            Name =  "RSAT"
        }
    }
}