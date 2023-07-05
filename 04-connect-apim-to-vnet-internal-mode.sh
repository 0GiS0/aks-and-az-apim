echo -e "${HIGHLIGHT} Connecting API Management to the virtual network ${NC}"

# Get API Management resource id
APIM_ID=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "id")

APIM_SUBNET_ID=$(az network vnet subnet show -g ${RESOURCE_GROUP} -n $APIM_SUBNET_NAME --vnet-name $VNET_NAME --query "id")

# Create a public IP for APIM
# With an internal virtual network, the public IP address is used only for management operations. Learn more about IP addresses of API Management. (https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#prerequisites)
echo -e "${HIGHLIGHT} Create a public IP for APIM ${NC}"
# When creating a public IP address resource, ensure you assign a DNS name label to it. The label you choose to use does not matter but a label is required if this resource will be assigned to an API Management service.
APIM_PUBLIC_IP_ID=$(az network public-ip create \
-g ${RESOURCE_GROUP} \
-n ${APIM_NAME}-pip \
--dns-name ${APIM_NAME} \
--sku Standard \
--query "publicIp.id" -o tsv)

# You must configure NSG group for the APIM subnet
echo -e "${HIGHLIGHT} You must configure NSG group for the APIM subnet ${NC}"

# Create security group
echo -e "${HIGHLIGHT} Create security group ${NC}"
APIM_NSG_NAME="${APIM_NAME}-nsg"
az network nsg create -g ${RESOURCE_GROUP} -n $APIM_NSG_NAME

# Create security group rules (https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2#configure-nsg-rules)
echo -e "${HIGHLIGHT} Create security group rule ${NC}"

az network nsg rule create \
-g ${RESOURCE_GROUP} \
--nsg-name $APIM_NSG_NAME \
--name ManagementEndpointForAzurePortalAndPowerShell \
--priority 100 \
--direction Inbound \
--source-address-prefixes '*' \
--source-port-ranges '*' \
--destination-address-prefixes '*' \
--destination-port-ranges 3443 \
--access Allow \
--protocol Tcp \
--description "Management endpoint for Azure portal and PowerShell"

az network nsg rule create \
-g ${RESOURCE_GROUP} \
--nsg-name $APIM_NSG_NAME \
--name AzureInfrastructureLoadBalancer	 \
--priority 101 \
--direction Inbound \
--source-address-prefixes '*' \
--source-port-ranges '*' \
--destination-address-prefixes '*' \
--destination-port-ranges 6390 \
--access Allow \
--protocol Tcp \
--description "Azure Infrastructure Load Balancer"

az network nsg rule create \
-g ${RESOURCE_GROUP} \
--nsg-name $APIM_NSG_NAME \
--name DependencyOnAzureStorage	\
--priority 102 \
--direction Outbound \
--source-address-prefixes '*' \
--source-port-ranges '*' \
--destination-address-prefixes '*' \
--destination-port-ranges 443 \
--access Allow \
--protocol Tcp \
--description "Dependency on Azure Storage"

az network nsg rule create \
-g ${RESOURCE_GROUP} \
--nsg-name $APIM_NSG_NAME \
--name AccessToAzureSQLendpoints	\
--priority 103 \
--direction Outbound \
--source-address-prefixes '*' \
--source-port-ranges '*' \
--destination-address-prefixes '*' \
--destination-port-ranges 1433 \
--access Allow \
--protocol Tcp \
--description "Access to Azure SQL endpoints"

az network nsg rule create \
-g ${RESOURCE_GROUP} \
--nsg-name $APIM_NSG_NAME \
--name AccessToAzureKeyVault		\
--priority 104 \
--direction Outbound \
--source-address-prefixes '*' \
--source-port-ranges '*' \
--destination-address-prefixes '*' \
--destination-port-ranges 433 \
--access Allow \
--protocol Tcp \
--description "Access to Azure Key Vault"

echo -e "${HIGHLIGHT}Associate NSG to APIM subnet${NC}"
az network vnet subnet update \
-n $APIM_SUBNET_NAME \
-g ${RESOURCE_GROUP} \
--vnet-name $VNET_NAME \
--network-security-group $APIM_NSG_NAME

echo -e "${HIGHLIGHT}Inject APIM in the vnet... (at $(date))${NC}"
time az resource update -n ${APIM_NAME} -g ${RESOURCE_GROUP} \
--resource-type Microsoft.ApiManagement/service \
--set properties.virtualNetworkType=Internal properties.virtualNetworkConfiguration.subnetResourceId=$APIM_SUBNET_ID properties.publicIpAddressId=$APIM_PUBLIC_IP_ID

echo -e "${HIGHLIGHT} Get internal APIM IP ${NC}"
APIM_PRIVATE_IP=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "privateIpAddresses[0]" -o tsv)

# Create private DNS with the custom domain(https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2#dns-configuration)
echo -e "${HIGHLIGHT} Create private DNS zone ${CUSTOM_DOMAIN}...${NC}"
az network private-dns zone create -g $RESOURCE_GROUP -n $CUSTOM_DOMAIN

# Link the private DNS zone to the virtual network
echo -e "${HIGHLIGHT} Link the private DNS zone to the virtual network...${NC}"
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP \
  --zone-name $CUSTOM_DOMAIN \
  --name $CUSTOM_DOMAIN-link \
  --virtual-network $VNET_NAME \
  --registration-enabled false

# Add records to the private DNS zone
echo -e "${HIGHLIGHT} Add records to the private DNS zone...${NC}"
az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $CUSTOM_DOMAIN \
--record-set-name $APIM_NAME \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $CUSTOM_DOMAIN \
--record-set-name api \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $CUSTOM_DOMAIN \
--record-set-name portal \
--ipv4-address $APIM_PRIVATE_IP

az network private-dns record-set a add-record \
--resource-group $RESOURCE_GROUP \
--zone-name $CUSTOM_DOMAIN \
--record-set-name management \
--ipv4-address $APIM_PRIVATE_IP