# https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2#dns-configuration

VM_SUBNET_NAME=vm-subnet

# Create a subnet for the VM
az network vnet subnet create \
--resource-group $RESOURCE_GROUP \
--vnet-name $VNET_NAME \
--name $VM_SUBNET_NAME \
--address-prefixes 192.168.4.0/24

VM_NAME=vm-jumpbox

RANDOM_PASSWORD=$(openssl rand -base64 32)
echo $RANDOM_PASSWORD

# Create Windows VM inside the VNET
az vm create \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--name $VM_NAME \
--image Win2019Datacenter \
--admin-username azureuser \
--admin-password $RANDOM_PASSWORD \
--vnet-name $VNET_NAME \
--subnet $VM_SUBNET_NAME
