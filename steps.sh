# Reference: https://learn.microsoft.com/en-us/azure/api-management/api-management-howto-integrate-internal-vnet-appgateway

# Set variables
source 00-variables.sh

# Create vnet and aks cluster
source 01-create-vnet-and-azure-private-dns.sh

# Create AKS and deploy ExternalDNS
source 02-create-aks-and-deploy-externaldns.sh

# Create apim instance
source 03-create-apim.sh

# Create custom domains for apim
# You have to execute this step manually: 03.1-apim-custom-domains.sh

# Connect apim to vnet
source 04-connect-apim-to-vnet-internal-mode.sh

# Create App Gateway
source 05-create-app-gateway.sh

# Create VM to access apim internally
source 06-create-vm-to-access-apim-internally.sh

# Configure App Gateway to use APIM as backend
source 07-configure-app-gateway-to-use-apim-as-backend.sh

# Deploy sample api
source 08-deploy-tour-of-heroes-api.sh

# Add tour of heroes api to apim
source 09-add-tour-of-heroes-api-to-apim.sh

# Call tour of heroes api through apim (It doesn't work because APIM is internal)
source 10-call-tour-of-heroes-api-through-apim.sh

# Get public IP of the App Gateway
APP_GW_PUBLIC_IP=$(az network public-ip show --name $APP_GW_PUBLIC_IP_NAME --resource-group $RESOURCE_GROUP --query ipAddress -o tsv)
echo "Update your DNS provider with the public IP of the App Gateway $APP_GW_PUBLIC_IP for the three subdomains"

# Call tour of heroes api through app gateway
source 11-call-tour-of-heroes-api-through-app-gateway.sh

# Deploy and publish Goat API
source 12-deploy-goat-api.sh

# Enable WAF and custom errors
source 13-enable-waf-and-custom-errors.sh