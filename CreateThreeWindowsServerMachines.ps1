#Login
$subName = "Visual Studio Enterprise"
Add-AzureAccount
Select-AzureSubscription -SubscriptionName "Visual Studio Enterprise"
Get-AzureLocation | Sort Name | Select Name, AvailableServices
$locName = "East US"

#Resource Group Creation,Storage Account & Virtual Network creation
$rgName ="TestingVMs"
New-AzureRmResourceGroup -Name $rgName -Location $locName
#Storage Account name needs to be unique
$saName = "testingvms"
$saType = "Standard_LRS"
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName –Type $saType -Location $locName

$subnetName = "TestingVmsSubnet"
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24
$netName = "testing"
$vnet = New-AzureRmVirtualNetwork -Name $netName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $subnet
$domName = "testingvms"
Test-AzureRmDnsAvailability -DomainQualifiedName $domName -Location $locName
$pipName = "publicIP"
$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic -DomainNameLabel $domName
$nicName = "testingvmsnic"
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
$ipName = "TestingVMsIP"
$ipConfig = New-AzureRmVmssIpConfig -Name $ipName -LoadBalancerBackendAddressPoolsId $null -SubnetId $vnet.Subnets[0].Id

$vmssConfig = "Testing VMs Scale Set"
$vmss = New-AzureRmVmssConfig -Location $locName -SkuCapacity 3 -SkuName "Standard_A0" -UpgradePolicyMode "manual"
Add-AzureRmVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmss -Name $vmssConfig -Primary $true -IPConfiguration $ipConfig

$computerName = "TestingVM"
$adminName = "Automation"
$adminPassword = "butter"
$storeProfile = "testingvmstore"
$imagePublisher = "MicrosoftWindowsServer"
$imageOffer = "WindowsServer"
$imageSku = "2012-R2-Datacenter"
$vhdContainer = "https://testingvms.blob.core.windows.net/testingvmdisk"

Set-AzureRmVmssStorageProfile -VirtualMachineScaleSet $vmss -ImageReferencePublisher $imagePublisher -ImageReferenceOffer $imageOffer -ImageReferenceSku $imageSku -ImageReferenceVersion "latest" -Name $storeProfile -VhdContainer $vhdContainer -OsDiskCreateOption "FromImage" -OsDiskCaching "None"  

$vmssName = "TestingVMsSS"
New-AzureRmVmss -ResourceGroupName $rgName -Name $vmssName -VirtualMachineScaleSet $vmss