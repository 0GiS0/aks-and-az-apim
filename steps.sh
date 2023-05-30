# Set variables
source 00-variables.sh

# Create vnet and aks cluster
source 01-create-vnet-and-azure-private-dns.sh

# Create AKS and deploy ExternalDNS
source 02-create-aks-and-deploy-externaldns.sh

# Create apim instance
source 03-create-apim.sh

# Connect apim to vnet
source 04-connect-apim-to-vnet.sh

# Optional - Fix APIM nsg
source 04.1-fix-apim-subnet-nsg.sh

# Deploy sample api
source 05-deploy-sample-api.sh

# Add tour of heroes api to apim
source 06-add-tour-of-heroes-api-to-apim.sh

# Optional - Fix AKS nsg
source 6.1-fix-aks-subnet-nsg.sh

# Call tour of heroes api through apim
source 07-call-tour-of-heroes-api-through-apim.sh