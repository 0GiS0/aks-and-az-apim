# Endpoints for custom domains
# There are several API Management endpoints to which you can assign a custom domain name. Currently, the following endpoints are available:

# Endpoint	Default
# Gateway	Default is: <apim-service-name>.azure-api.net. Gateway is the only endpoint available for configuration in the Consumption tier.

# The default Gateway endpoint configuration remains available after a custom Gateway domain is added.
# Developer portal (legacy)	Default is: <apim-service-name>.portal.azure-api.net
# Developer portal	Default is: <apim-service-name>.developer.azure-api.net
# Management	Default is: <apim-service-name>.management.azure-api.net
# Configuration API (v2)	Default is: <apim-service-name>.configuration.azure-api.net
# SCM	Default is: <apim-service-name>.scm.azure-api.net

# https://stackoverflow.com/questions/64851783/azure-cli-bash-script-to-set-up-api-management-custom-domain

# Create certificates using certbot

# Install certbot
brew install certbot

# Create certificate
CERT_PASSWORD="1234"
EMAIL="giselatb@outlook.com"
# LETSENCRYPT_URL="https://acme-staging-v02.api.letsencrypt.org/directory"
LETSENCRYPT_URL="https://acme-v02.api.letsencrypt.org/directory"


echo -e "${HIGHLIGHT} Request certificate for management.$CUSTOM_DOMAIN ${NC}"
sudo certbot certonly \
--manual --preferred-challenges dns \
--email $EMAIL --server $LETSENCRYPT_URL \
--agree-tos -d management.$CUSTOM_DOMAIN

echo -e "${HIGHLIGHT} Export certificate for management.$CUSTOM_DOMAIN ${NC}"
sudo openssl pkcs12 -export -out ./management.$CUSTOM_DOMAIN.pfx \
-inkey /etc/letsencrypt/live/management.$CUSTOM_DOMAIN/privkey.pem \
-in /etc/letsencrypt/live/management.$CUSTOM_DOMAIN/fullchain.pem \
-passout pass:$CERT_PASSWORD

echo -e "${HIGHLIGHT} Request certificate for api.$CUSTOM_DOMAIN ${NC}"
sudo certbot certonly \
--manual --preferred-challenges dns \
--email $EMAIL --server $LETSENCRYPT_URL \
--agree-tos -d api.$CUSTOM_DOMAIN

echo -e "${HIGHLIGHT} Export certificate for api.$CUSTOM_DOMAIN ${NC}"
sudo openssl pkcs12 -export -out ./api.$CUSTOM_DOMAIN.pfx \
-inkey /etc/letsencrypt/live/api.$CUSTOM_DOMAIN/privkey.pem \
-in /etc/letsencrypt/live/api.$CUSTOM_DOMAIN/fullchain.pem \
-passout pass:$CERT_PASSWORD

echo -e "${HIGHLIGHT} Request certificate for portal.$CUSTOM_DOMAIN ${NC}"
sudo certbot certonly \
--manual --preferred-challenges dns \
--email $EMAIL --server $LETSENCRYPT_URL \
--agree-tos -d portal.$CUSTOM_DOMAIN

echo -e "${HIGHLIGHT} Export certificate for portal.$CUSTOM_DOMAIN ${NC}"
sudo openssl pkcs12 -export -out ./portal.$CUSTOM_DOMAIN.pfx \
-inkey /etc/letsencrypt/live/portal.$CUSTOM_DOMAIN/privkey.pem \
-in /etc/letsencrypt/live/portal.$CUSTOM_DOMAIN/fullchain.pem \
-passout pass:$CERT_PASSWORD


API_ENCODED_CERT_DATA=$(base64 -i ./api.$CUSTOM_DOMAIN.pfx)
PORTAL_ENCODED_CERT_DATA=$(base64 -i ./portal.$CUSTOM_DOMAIN.pfx)
MANAGEMENT_ENCODED_CERT_DATA=$(base64 -i ./management.$CUSTOM_DOMAIN.pfx)

# Settings for custom domains
hostnamesConfiguration="[
    {
      \"hostName\": \"api.$CUSTOM_DOMAIN\",      
      \"type\": \"Proxy\",
      \"encodedCertificate\": \"$API_ENCODED_CERT_DATA\",
      \"certificatePassword\": \"$CERT_PASSWORD\"
    }, 
    {
        \"hostName\": \"portal.$CUSTOM_DOMAIN\",
        \"type\": \"DeveloperPortal\",        
        \"encodedCertificate\": \"$PORTAL_ENCODED_CERT_DATA\",
        \"certificatePassword\": \"$CERT_PASSWORD\"
    },
    {
        \"hostName\": \"management.$CUSTOM_DOMAIN\",
        \"type\": \"Management\",        
        \"encodedCertificate\": \"$MANAGEMENT_ENCODED_CERT_DATA\",
        \"certificatePassword\": \"$CERT_PASSWORD\"
    }

]"

echo -e "${HIGHLIGHT} Configure custom domains${NC}"
az apim update \
--resource-group $RESOURCE_GROUP \
--name $APIM_NAME \
--set hostnameConfigurations=$hostnamesConfiguration

# Get custom domains configured for API Management
az apim show --name $APIM_NAME --resource-group $RESOURCE_GROUP --query "hostnameConfigurations" -o table