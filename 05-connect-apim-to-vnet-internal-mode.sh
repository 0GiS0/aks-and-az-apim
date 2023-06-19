echo -e "${GREEN} Connecting API Management to the virtual network ${NC}"

# Get API Management resource id
APIM_ID=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "id")

APIM_SUBNET_ID=$(az network vnet subnet show -g ${RESOURCE_GROUP} -n $APIM_SUBNET_NAME --vnet-name $VNET_NAME --query "id")

# Create a public IP for APIM
# With an internal virtual network, the public IP address is used only for management operations. Learn more about IP addresses of API Management. (https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2#prerequisites)
echo -e "${GREEN} Create a public IP for APIM ${NC}"
# When creating a public IP address resource, ensure you assign a DNS name label to it. The label you choose to use does not matter but a label is required if this resource will be assigned to an API Management service.
APIM_PUBLIC_IP_ID=$(az network public-ip create \
-g ${RESOURCE_GROUP} \
-n ${APIM_NAME}-pip \
--dns-name ${APIM_NAME} \
--sku Standard \
--query "publicIp.id" -o tsv)

# You must configure NSG group for the APIM subnet
echo -e "${GREEN} You must configure NSG group for the APIM subnet ${NC}"

# Create security group
echo -e "${GREEN} Create security group ${NC}"
APIM_NSG_NAME="${APIM_NAME}-nsg"
az network nsg create -g ${RESOURCE_GROUP} -n $APIM_NSG_NAME

# Create security group rules (https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2#configure-nsg-rules)
echo -e "${GREEN} Create security group rule ${NC}"
# External Only
# az network nsg rule create \
# -g ${RESOURCE_GROUP} \
# --nsg-name $APIM_NSG_NAME \
# --name ClientCommunicationToAPIM \
# --priority 100 \
# --source-address-prefixes '*' \
# --source-port-ranges '*' \
# --destination-address-prefixes '*' \
# --destination-port-ranges 80 443 \
# --access Allow \
# --protocol Tcp \
# --description "Client communication to API Management"

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

echo -e "${GREEN}Associate NSG to APIM subnet${NC}"
az network vnet subnet update \
-n $APIM_SUBNET_NAME \
-g ${RESOURCE_GROUP} \
--vnet-name $VNET_NAME \
--network-security-group $APIM_NSG_NAME


time az resource update -n ${APIM_NAME} -g ${RESOURCE_GROUP} \
--resource-type Microsoft.ApiManagement/service \
--set properties.virtualNetworkType=Internal properties.virtualNetworkConfiguration.subnetResourceId=$APIM_SUBNET_ID \
--set properties.publicIpAddressId=$APIM_PUBLIC_IP_ID

echo -e "${GREEN} Get internal APIM IP ${NC}"
APIM_PRIVATE_IP=$(az apim show -n ${APIM_NAME} -g ${RESOURCE_GROUP} --query "privateIpAddresses[0]" -o tsv)

# Create private DNS with the name of the API Management instance (https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2#dns-configuration)
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