echo -e "${GREEN} Configuring App Gw to use APIM as backend... ${NC}"

echo -e "${GREEN} Create APIM backend pool with the API Management service ${NC}"
az network application-gateway address-pool create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim \
--servers $APIM_NAME.azure-api.net

# Create a sink pool for API Management requests we want to discard
# az network application-gateway address-pool create \
# --gateway-name $APP_GW_NAME \
# --resource-group $RESOURCE_GROUP \
# --name sinkPool

# Configure frontend ports
# echo -e "${GREEN} Configure frontend ports ${NC}"
# az network application-gateway frontend-port create \
# --gateway-name $APP_GW_NAME \
# --resource-group $RESOURCE_GROUP \
# --name port_80 \
# --port 80

az network application-gateway frontend-port create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name port_443 \
--port 443

echo -e "${GREEN} Check frontend ports ${NC}"
az network application-gateway frontend-port list --gateway-name $APP_GW_NAME -g $RESOURCE_GROUP

# Probe health for API Management
az network application-gateway probe create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-gw-health-probe" \
--path "/status-0123456789abcdef" \
--host-name-from-http-settings true \
--protocol "Http" \
--interval 30 \
--threshold 3 \
--timeout 30 

# Create http settings for Http 
az network application-gateway http-settings create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "http" \
--port 80 \
--protocol Http \
--cookie-based-affinity Disabled \
--timeout 20 \
--probe "apim-gw-health-probe" \
--host-name-from-backend-pool true

# Probe health for API Management https
az network application-gateway probe create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-gw-health-probe-https" \
--path "/status-0123456789abcdef" \
--host-name-from-http-settings true \
--protocol "Https" \
--interval 30 \
--threshold 3 \
--timeout 30 

# Create http settings for Https
az network application-gateway http-settings create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "https" \
--port 443 \
--protocol Https \
--cookie-based-affinity Disabled \
--timeout 20 \
--host-name-from-backend-pool true \
--probe "apim-gw-health-probe-https"


# Generate self-signed certificate
echo -e "${GREEN} Generate self-signed certificate ${NC}"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout appGatewaySslCert.key -out appGatewaySslCert.crt -subj "/CN=${APIM_NAME}.azure-api.net/O=${APIM_NAME}.azure-api.net"
openssl pkcs12 -export -out appGatewaySslCert.pfx -inkey appGatewaySslCert.key -in appGatewaySslCert.crt -passout pass:1234

echo -e "${GREEN} Upload certificate to Azure ${NC}"
az network application-gateway ssl-cert create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name appGatewaySslCert \
--cert-file appGatewaySslCert.pfx \
--cert-password "1234"

echo -e "${GREEN} Create http listener for Https ${NC}"
az network application-gateway http-listener create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "https" \
--frontend-ip appGatewayFrontendIP \
--frontend-port port_443 \
--ssl-cert appGatewaySslCert

#Create rule that glues the listener and the backend pool for https
az network application-gateway rule create \
--gateway-name $APP_GW_NAME \
--name "https" \
--resource-group $RESOURCE_GROUP \
--http-listener "https" \
--rule-type "Basic" \
--address-pool "apim" \
--http-settings "https" \
--priority 2


#Update default rule that glues the listener and the backend pool
az network application-gateway rule update \
--gateway-name $APP_GW_NAME \
--name "rule1" \
--resource-group $RESOURCE_GROUP \
--http-listener "appGatewayHttpListener" \
--rule-type "Basic" \
--address-pool "apim" \
--http-settings "http" \
--priority 1

# Delete default http settings
echo -e "${GREEN} Delete default http settings ${NC}"
az network application-gateway http-settings delete \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "appGatewayBackendHttpSettings"

# Delete default backend pool
echo -e "${GREEN} Delete default backend pool ${NC}"
az network application-gateway address-pool delete \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "appGatewayBackendPool"

echo -e "${GREEN} Done 🫡... ${NC}"