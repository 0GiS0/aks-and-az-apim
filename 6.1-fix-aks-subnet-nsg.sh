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