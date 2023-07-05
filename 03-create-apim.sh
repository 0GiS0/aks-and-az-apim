echo "${HIGHLIGHT} Creating API Management instance at $(date)...${NC}"

time az apim create \
--resource-group ${RESOURCE_GROUP} \
--name ${APIM_NAME} \
--location ${LOCATION} \
--publisher-email "your@email.com" \
--publisher-name "return(GiS);" \
--sku-name Developer

echo -e "${HIGHLIGHT} API Management instance created${NC}"

echo -e "${HIGHLIGHT} Create private DNS zone ${CUSTOM_DOMAIN} to resolve the custom domain internally...${NC}"
az network private-dns zone create -g $RESOURCE_GROUP -n $CUSTOM_DOMAIN

echo -e "${HIGHLIGHT} Link the private DNS zone to the virtual network...${NC}"
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name $CUSTOM_DOMAIN \
  --name $CUSTOM_DOMAIN-link \
  --virtual-network $VNET_NAME \
  --registration-enabled false

echo -e "${HIGHLIGHT}Done 👍🏻${NC}"
