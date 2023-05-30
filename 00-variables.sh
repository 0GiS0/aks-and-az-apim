RESOURCE_GROUP="aks-and-apim-demo"
LOCATION="westeurope"

PRIVATE_DNS_ZONE_NAME="tour-of-heroes.internal"
VNET_NAME="aks-and-apim-vnet"
AKS_SUBNET_NAME="aks-subnet"
APIM_SUBNET_NAME="apim-subnet"

AKS_NAME="aks-cluster"
APIM_NAME="apim-demo-${RANDOM}"

# Colors for the output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Variables set 👍${NC}"