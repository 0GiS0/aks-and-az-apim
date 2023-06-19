RESOURCE_GROUP="waf-apim-aks-poc"
LOCATION="westeurope"

PRIVATE_DNS_ZONE_NAME="apis.internal"
VNET_NAME="aks-and-apim-vnet"
AKS_SUBNET_NAME="aks-subnet"
APIM_SUBNET_NAME="apim-subnet"

AKS_NAME="aks-cluster"
APIM_NAME="apim-demo-${RANDOM}"

APP_GW_NAME="app-gw"
APP_GW_PUBLIC_IP_NAME="app-gw-ip"
APP_GW_SUBNET_NAME="app-gw-subnet"

#Remove dashes from APIM name
APIM_NAME_WITHOUT_DASHES=${APIM_NAME//-/}

STORAGE_ACCOUNT_NAME="${APIM_NAME_WITHOUT_DASHES}storage"

# Colors for the output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Variables set 👍${NC}"