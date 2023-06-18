echo "${GREEN} Creating API Management instance..."

time az apim create \
--resource-group ${RESOURCE_GROUP} \
--name ${APIM_NAME} \
--location ${LOCATION} \
--publisher-email "your@email.com" \
--publisher-name "return(GiS);" \
--sku-name Developer

echo -e "${GREEN} API Management instance created${NC}"

echo -e "${GREEN} Setup custom domain names ${NC}"

# Create private DNS with the name of the API Management instance
DEFAULT_API_DOMAIN="azure-api.net"
echo -e "${GREEN} Create private DNS zone ${DEFAULT_API_DOMAIN}...${NC}"
DEFAULT_API_DNS_ZONE_ID=$(az network private-dns zone create -g $RESOURCE_GROUP -n $DEFAULT_API_DOMAIN --query id -o tsv)

# Link the private DNS zone to the virtual network
echo -e "${GREEN} Link the private DNS zone to the virtual network...${NC}"
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DEFAULT_API_DOMAIN \
  --name $DEFAULT_API_DOMAIN \
  --virtual-network $VNET_NAME \
  --registration-enabled false

# Add records to the private DNS zone
echo -e "${GREEN} Add records to the private DNS zone...${NC}"
az network private-dns record-set a add-record \
  --resource-group $RESOURCE_GROUP \
  --zone-name $DEFAULT_API_DOMAIN \
  --record-set-name $APIM_NAME \
  --ipv4-address
