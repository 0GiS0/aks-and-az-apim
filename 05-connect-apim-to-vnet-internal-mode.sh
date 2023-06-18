echo -e "${GREEN} Connecting API Management to the virtual network ${NC}"

# Get API Management resource id
APIM_ID=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "id")

APIM_SUBNET_ID=$(az network vnet subnet show -g ${RESOURCE_GROUP} -n $APIM_SUBNET_NAME --vnet-name $VNET_NAME --query "id")

time az resource update -n ${APIM_NAME} -g ${RESOURCE_GROUP} \
--resource-type Microsoft.ApiManagement/service \
--set properties.virtualNetworkType=Internal properties.virtualNetworkConfiguration.subnetResourceId=$APIM_SUBNET_ID

echo -e "${GREEN} Get internal APIM IP ${NC}"
APIM_PRIVATE_IP=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "privateIpAddresses[0]" -o tsv)


# Create private DNS with the name of the API Management instance
DEFAULT_APIM_DOMAIN="azure-api.net"
echo -e "${GREEN} Create private DNS zone ${DEFAULT_API_DOMAIN}...${NC}"
DEFAULT_API_DNS_ZONE_ID=$(az network private-dns zone create -g $RESOURCE_GROUP -n $DEFAULT_APIM_DOMAIN --query id -o tsv)

# Link the private DNS zone to the virtual network
echo -e "${GREEN} Link the private DNS zone to the virtual network...${NC}"
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DEFAULT_APIM_DOMAIN \
  --name $DEFAULT_API_DOMAIN \
  --virtual-network $VNET_NAME \
  --registration-enabled false

# Add records to the private DNS zone
echo -e "${GREEN} Add records to the private DNS zone...${NC}"
az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $DEFAULT_API_DOMAIN \
--record-set-name $APIM_NAME \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $DEFAULT_API_DOMAIN \
--record-set-name $APIM_NAME.portal \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $DEFAULT_API_DOMAIN \
--record-set-name $APIM_NAME.developer \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $DEFAULT_API_DOMAIN \
--record-set-name $APIM_NAME.management \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $DEFAULT_API_DOMAIN \
--record-set-name $APIM_NAME.scm \
--ipv4-address $APIM_PRIVATE_IP