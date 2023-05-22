echo -e "${GREEN} Create an api in API Management ${NC}"
az apim api create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--path /tour-of-heroes-api \
--display-name "Tour of Heroes API" \
--service-url http://${INTERNAL_IP_API}/api/hero \
--protocols http

echo -e "${GREEN} Add GET operation to API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--url-template / \
--method GET \
--display-name "Get all heroes"

echo -e "${GREEN} Add POST operation to API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--url-template / \
--method POST \
--display-name "Add hero"

# Get NSG id
NSG_ID=$(az network vnet subnet show -n $AKS_SUBNET_NAME -g $RESOURCE_GROUP --vnet-name $VNET_NAME --query networkSecurityGroup.id -o tsv)

# if nsg exists, get the name
if [ -z "$NSG_ID" ]; then
    echo -e "${GREEN}No NSG found${NC}"
else
   # Get the NSG name
    NSG_NAME=$(az network nsg show --ids $NSG_ID --query name -o tsv)
    # Enable port 80 in AKS NSG subnet
    az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG_NAME \
    --name Allow-HTTP-All \
    --priority 100 \
    --destination-port-ranges 80 \
    --access Allow \
    --protocol Tcp
fi


echo -e "${GREEN} Test tour of heroes API ${NC}"
curl http://${INTERNAL_IP_API}/api/hero