                
                
                
                
                
                
                
                
                
                
                # If no specific vnet resource group is specified, use existing group
                if (!$VnetResourceGroupName){
                    $VnetResourceGroupName = $ResourceGroupName
                }
                
                $Vnet = New-Vnet `
                -SubscriptionID $SubscriptionID `
                -ResourceGroupName $VnetResourceGroupName `
                -VNetName $VnetName `
                -Location $Location `
                -SubnetName $SubnetName `
                -VNetAddressPrefix $VNetAddressPrefix `
                -VNetSubnetAddressPrefix $VNetSubnetAddressPrefix `
                -Credential $credential
            }