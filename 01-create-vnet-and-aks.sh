echo -e "${GREEN}Creating resource group ${RESOURCE_GROUP} in ${LOCATION}..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}

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

echo -e "${GREEN}Creating an identity for AKS..."
az identity create \
--resource-group ${RESOURCE_GROUP} \
--name ${AKS_NAME}-identity

echo -e "${HIGHLIGHT}Waiting 60 seconds for the identity..."
sleep 60
IDENTITY_ID=$(az identity show --name $AKS_NAME-identity --resource-group $RESOURCE_GROUP --query id -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name $AKS_NAME-identity --resource-group $RESOURCE_GROUP --query clientId -o tsv)

# Get VNET id
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query id -o tsv)

# Assign Network Contributor role to the user identity
echo -e "${GREEN}Assign roles to the identity 🎟️ ..."
az role assignment create --assignee $IDENTITY_CLIENT_ID --scope $VNET_ID --role "Network Contributor"
# Permission granted to your cluster's managed identity used by Azure may take up 60 minutes to populate.

# Get roles assigned to the user identity
az role assignment list --assignee $IDENTITY_CLIENT_ID --all -o table

AKS_SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $AKS_SUBNET_NAME --query id -o tsv)


echo -e "${GREEN}Creating AKS cluster ${AKS_NAME} in ${RESOURCE_GROUP}..."
time az aks create \
--resource-group ${RESOURCE_GROUP} \
--name ${AKS_NAME} \
--node-vm-size Standard_B4ms \
--node-count 1 \
--enable-managed-identity \
--vnet-subnet-id $AKS_SUBNET_ID \
--assign-identity $IDENTITY_ID \
--enable-addons monitoring \
--generate-ssh-keys


echo -e "${GREEN}Getting AKS credentials..."
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_NAME} --overwrite-existing