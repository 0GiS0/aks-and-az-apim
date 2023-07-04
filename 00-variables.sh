CUSTOM_DOMAIN="thedev.es"

RESOURCE_GROUP="waf-apim-aks-${CUSTOM_DOMAIN//./}"
LOCATION="westeurope"

PRIVATE_DNS_ZONE_NAME="apis.internal"
VNET_NAME="aks-and-apim-vnet"
AKS_SUBNET_NAME="aks-subnet"
APIM_SUBNET_NAME="apim-subnet"

AKS_NAME="aks-cluster"
APIM_NAME="apim-demo-${CUSTOM_DOMAIN//./}"

APP_GW_NAME="app-gw"
APP_GW_PUBLIC_IP_NAME="app-gw-ip"
APP_GW_SUBNET_NAME="app-gw-subnet"

STORAGE_ACCOUNT_NAME="${APIM_NAME//-/}storage"

APP_GW_PUBLIC_IP_DNS_NAME="${CUSTOM_DOMAIN//./}"

# Colors for the output
RED='\033[0;31m'
# Highlight text with yellow background
HIGHLIGHT='\033[0;30;43m'
NC='\033[0m'

echo -e "${HIGHLIGHT}Variables set 👍${NC}"