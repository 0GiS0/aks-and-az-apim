echo -e "${GREEN}Creating resource group ${RESOURCE_GROUP} in ${LOCATION}..."
RESOURCE_GROUP_ID=$(az group create --name ${RESOURCE_GROUP} --location ${LOCATION} --query id -o tsv)

echo -e "${GREEN}Creating vnet ${VNET_NAME} in ${RESOURCE_GROUP}..."
az network vnet create \
--resource-group ${RESOURCE_GROUP} \
--name ${VNET_NAME} \
--address-prefixes 192.168.0.0/16 \
--subnet-name ${AKS_SUBNET_NAME} \
--subnet-prefix 192.168.1.0/24

echo -e "${GREEN}Creating apim subnet ${APIM_SUBNET_NAME} in ${RESOURCE_GROUP}..."
# But https://learn.microsoft.com/en-us/azure/api-management/virtual-network-concepts?tabs=stv2#examples
az network vnet subnet create \
--resource-group ${RESOURCE_GROUP} \
--vnet-name ${VNET_NAME} \
--name ${APIM_SUBNET_NAME} \
--address-prefixes 192.168.2.0/28

echo -e "${GREEN}Create private DNS zone $PRIVATE_DNS_ZONE_NAME...${NC}"
PRIVATE_DNS_ZONE_ID=$(az network private-dns zone create -g $RESOURCE_GROUP -n $PRIVATE_DNS_ZONE_NAME --query id -o tsv)

# Link the private DNS zone to the virtual network
echo -e "${GREEN}Link the private DNS zone to the virtual network...${NC}"
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name $PRIVATE_DNS_ZONE_NAME \
  --name $PRIVATE_DNS_ZONE_NAME \
  --virtual-network $VNET_NAME \
  --registration-enabled false