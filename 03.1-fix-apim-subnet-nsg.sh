# https://learn.microsoft.com/en-us/azure/api-management/virtual-network-reference?tabs=stv2
# Fix inbound ports for API Management
NSG_RESOURCE_ID=$(az network vnet subnet show --name $APIM_SUBNET_NAME --vnet-name $VNET_NAME --resource-group $RESOURCE_GROUP --query networkSecurityGroup.id -o tsv)

if [ -z "$NSG_ID" ]; then
    echo -e "${GREEN}No NSG found${NC}"
else
  
    # Get the name of the resouce by the resource Id
    NSG_NAME=$(az resource show --ids $NSG_RESOURCE_ID --query name -o tsv)

    # Add ngs rules for Api Management control plane inbound
    az network nsg rule create \
    --name "AllowApiManagementControlPlaneInbound" \
    --nsg-name $NSG_NAME \
    --resource-group $RESOURCE_GROUP \
    --access Allow \
    --direction Inbound \
    --destination-port-ranges 3443 \
    --priority 1000 \
    --protocol Tcp

    # Add ngs rules for allow client communication to api management 80 
    az network nsg rule create \
    --name "AllowClientCommunicationToAPIManagement_80" \
    --nsg-name $NSG_NAME \
    --resource-group $RESOURCE_GROUP \
    --access Allow \
    --direction Inbound \
    --destination-port-ranges 80 \
    --priority 1001 \
    --protocol Tcp

    # Add ngs rules for allow client communication to api management 443 
    az network nsg rule create \
    --name "AllowClientCommunicationToAPIManagement_443" \
    --nsg-name $NSG_NAME \
    --resource-group $RESOURCE_GROUP \
    --access Allow \
    --direction Inbound \
    --destination-port-ranges 443 \
    --priority 1002 \
    --protocol Tcp
fi
