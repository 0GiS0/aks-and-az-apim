# Set variables
source 00-variables.sh

# Create vnet and aks cluster
source 01-create-vnet-and-aks.sh

# Create apim instance
source 02-create-apim.sh

# Connect apim to vnet
source 03-connect-apim-to-vnet.sh

# Optional - Fix APIM nsg
source 03.1-fix-apim-subnet-nsg.sh

# Deploy sample api
source 04-deploy-sample-api.sh

# Add tour of heroes api to apim
source 05-add-tour-of-heroes-api-to-apim.sh

# Optional - Fix AKS nsg
source 05.1-fix-aks-subnet-nsg.sh

# Call tour of heroes api through apim
source 06-call-tour-of-heroes-api-through-apim.sh