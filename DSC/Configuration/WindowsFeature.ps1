# DSC configuration definition
Configuration WindowsFeature {
    Param(
        [Parameter(
            Mandatory = $true,
            HelpMessage="Enter the feature name"
        )]
        [string]
        $FeatureName,
        [parameter(
            Mandatory = $false
        )]
        [PSCredential]
        $StorageCredential,
        [parameter(
            Mandatory = $false
        )]
        [string]
        $ShareSource,
        [parameter(
            Mandatory = $false
        )]
        [string]
        $SXSSource
    )

    # Import module
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    
    # Node configuration
    Node RequireFeature {
        # Features
        WindowsFeature FeaturePresent {
            Name = $FeatureName
            Ensure = "Present"
            DependsOn = "[Script]MapShare"
            Source = $SXSSource
        }
        Script MapShare {
            SetScript = {
                # Map drive
                New-PSDrive -Name Z -PSProvider FileSystem -root $ShareSource -Credential $StorageCredential -Persist
            }
            TestScript = {
                # Check if drive is mapped
                Test-Path -path "Z:"
            }
            GetScript = {
                # Create hash table for mapping status
                @{
                    "Present" = Test-Path -path "Z:"
                }
            }
        }
    }
    Node NotRequireFeature {
        # Features
        WindowsFeature FeatureAbsent {
            Name = $FeatureName
            Ensure = "Absent"
        }
    }
}