echo -e "${GREEN} Connecting API Management to the virtual network ${NC}"

# Get API Management resource id
APIM_ID=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "id")

APIM_SUBNET_ID=$(az network vnet subnet show -g ${RESOURCE_GROUP} -n $APIM_SUBNET_NAME --vnet-name $VNET_NAME --query "id")

time az resource update -n ${APIM_NAME} -g ${RESOURCE_GROUP} \
--resource-type Microsoft.ApiManagement/service \
--set properties.virtualNetworkType=External properties.virtualNetworkConfiguration.subnetResourceId=$APIM_SUBNET_ID