
echo -e "${HIGHLIGHT}Getting the newest image of Windows 11${NC}"
WIN11_VM_IMAGES=$(az vm image list --publisher "microsoftwindowsdesktop" --architecture "x64" --offer "Windows-11" --location $LOCATION --all)
# Get the newest image
WIN11_VM_IMAGE=$(echo $WIN11_VM_IMAGES | jq -r '.[0].urn')


VM_SUBNET_NAME=vm-subnet
echo -e "${HIGHLIGHT}Create a subnet for the VM...${NC}"
az network vnet subnet create \
--resource-group $RESOURCE_GROUP \
--vnet-name $VNET_NAME \
--name $VM_SUBNET_NAME \
--address-prefixes 192.168.4.0/24

VM_NAME=vm-jumpbox

RANDOM_PASSWORD=$(openssl rand -base64 32)

echo -e "${HIGHLIGHT}Create Windows VM inside the VNET with password ${RANDOM_PASSWORD}${NC}"
az vm create \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--name $VM_NAME \
--image $WIN11_VM_IMAGE \
--admin-username azureuser \
--admin-password $RANDOM_PASSWORD \
--vnet-name $VNET_NAME \
--subnet $VM_SUBNET_NAME