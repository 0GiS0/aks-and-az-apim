echo -e "${HIGHLIGHT}Configuring App Gw to use APIM as backend... ${NC}"

echo -e "${HIGHLIGHT}Create APIM backend pool with the API Management service ${NC}"
az network application-gateway address-pool create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-portal \
--servers portal.$CUSTOM_DOMAIN

az network application-gateway address-pool create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-gateway \
--servers api.$CUSTOM_DOMAIN

az network application-gateway address-pool create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-management \
--servers management.$CUSTOM_DOMAIN

echo -e "${HIGHLIGHT}Create 443 frontend port... ${NC}"
az network application-gateway frontend-port create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name port_443 \
--port 443

echo -e "${HIGHLIGHT} Check frontend ports ${NC}"
az network application-gateway frontend-port list --gateway-name $APP_GW_NAME -g $RESOURCE_GROUP -o table


echo -e "${HIGHLIGHT}Create health probes for the backends${NC}"

az network application-gateway probe create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-api-probe" \
--path "/status-0123456789abcdef" \
--host-name-from-http-settings true \
--protocol "Https" \
--interval 30 \
--threshold 3 \
--timeout 30

az network application-gateway probe create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-management-probe" \
--path "/ServiceStatus" \
--host-name-from-http-settings true \
--protocol "Https" \
--interval 30 \
--threshold 3 \
--timeout 30

az network application-gateway probe create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-portal-probe" \
--path "/signin" \
--host-name-from-http-settings true \
--protocol "Https" \
--interval 30 \
--threshold 3 \
--timeout 30

echo -e "${HIGHLIGHT}Create backend settings${NC}"

az network application-gateway http-settings create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-api" \
--port 443 \
--protocol Https \
--cookie-based-affinity Disabled \
--timeout 20 \
--probe "apim-api-probe" \
--host-name-from-backend-pool true

az network application-gateway http-settings create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-management" \
--port 443 \
--protocol Https \
--cookie-based-affinity Disabled \
--timeout 20 \
--probe "apim-management-probe" \
--host-name-from-backend-pool true

az network application-gateway http-settings create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "apim-portal" \
--port 443 \
--protocol Https \
--cookie-based-affinity Disabled \
--timeout 20 \
--probe "apim-portal-probe" \
--host-name-from-backend-pool true

echo -e "${HIGHLIGHT} Upload certificates to App Gw...${NC}"
sudo az network application-gateway ssl-cert create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-api \
--cert-file api.$CUSTOM_DOMAIN.pfx \
--cert-password $CERT_PASSWORD

sudo az network application-gateway ssl-cert create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-management \
--cert-file management.$CUSTOM_DOMAIN.pfx \
--cert-password $CERT_PASSWORD

sudo az network application-gateway ssl-cert create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-portal \
--cert-file portal.$CUSTOM_DOMAIN.pfx \
--cert-password $CERT_PASSWORD


echo -e "${HIGHLIGHT} Create listeners for the endpoints...${NC}"
az network application-gateway http-listener create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "portal.$CUSTOM_DOMAIN" \
--frontend-ip appGatewayFrontendIP \
--frontend-port port_443 \
--ssl-cert apim-portal \
--host-name portal.$CUSTOM_DOMAIN

az network application-gateway http-listener create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "api.$CUSTOM_DOMAIN" \
--frontend-ip appGatewayFrontendIP \
--frontend-port port_443 \
--ssl-cert apim-api \
--host-name api.$CUSTOM_DOMAIN

az network application-gateway http-listener create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "management.$CUSTOM_DOMAIN" \
--frontend-ip appGatewayFrontendIP \
--frontend-port port_443 \
--ssl-cert apim-management \
--host-name management.$CUSTOM_DOMAIN

echo -e "${HIGHLIGHT}Create rules that glue the listeners and the backend pools...${NC}"
az network application-gateway rule create \
--gateway-name $APP_GW_NAME \
--name "apim-portal-rule" \
--resource-group $RESOURCE_GROUP \
--http-listener "portal.$CUSTOM_DOMAIN" \
--rule-type "Basic" \
--address-pool "apim-portal" \
--http-settings "apim-portal" \
--priority 100

az network application-gateway rule create \
--gateway-name $APP_GW_NAME \
--name "apim-api-rule" \
--resource-group $RESOURCE_GROUP \
--http-listener "api.$CUSTOM_DOMAIN" \
--rule-type "Basic" \
--address-pool "apim-gateway" \
--http-settings "apim-api" \
--priority 101

az network application-gateway rule create \
--gateway-name $APP_GW_NAME \
--name "apim-management-rule" \
--resource-group $RESOURCE_GROUP \
--http-listener "management.$CUSTOM_DOMAIN" \
--rule-type "Basic" \
--address-pool "apim-management" \
--http-settings "apim-management" \
--priority 102

echo -e "${HIGHLIGHT} Check backend health ${NC}"
az network application-gateway show-backend-health \
--name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP  \
--query "backendAddressPools[].backendHttpSettingsCollection[].servers[]" -o table

echo -e "${HIGHLIGHT}Delete default settings...${NC}"

echo -e "${HIGHLIGHT}Delete rule1${NC}"
az network application-gateway rule delete \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "rule1"

echo -e "${HIGHLIGHT}Delete appGatewayHttpListener${NC}"
az network application-gateway http-listener delete \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "appGatewayHttpListener"

echo -e "${HIGHLIGHT}Check appGatewayBackendHttpSettings ${NC}"
az network application-gateway http-settings delete \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "appGatewayBackendHttpSettings"

# Delete default backend pool
echo -e "${HIGHLIGHT}Delete default backend pool ${NC}"
az network application-gateway address-pool delete \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "appGatewayBackendPool"

echo -e "${HIGHLIGHT} Done 🫡... ${NC}"