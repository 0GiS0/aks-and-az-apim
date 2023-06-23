echo -e "${GREEN} Create backend pool for the management endpoint ${NC}"
az network application-gateway address-pool create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-portal \
--servers $APIM_NAME.management.azure-api.net

echo -e "${GREEN} Create backend pool for the developer portal ${NC}"
az network application-gateway address-pool create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-portal \
--servers $APIM_NAME.developer.azure-api.net

echo -e "${GREEN} Listing frontend ports ${NC}"
az network application-gateway frontend-port list --gateway-name $APP_GW_NAME -g $RESOURCE_GROUP -o table

echo -e "${GREEN} Create frontend port for the developer portal ${NC}"
az network application-gateway frontend-port create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name port_8080 \
--port 8080

echo -e "${GREEN} Creating listener for the developer portal ${NC}"
az network application-gateway http-listener create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name apim-developer-listener \
--frontend-port port_8080

echo -e "${GREEN} Create health probe for the developer portal ${NC}"
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

echo -e "${GREEN} Creating backend settings ${NC}"
az network application-gateway http-settings create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "http-developer" \
--port 443 \
--protocol Https \
--timeout 20 \
--probe "apim-portal-probe" \
--host-name-from-backend-pool true

echo -e "${GREEN} Creating rule developer portal ${NC}"
az network application-gateway rule create \
--gateway-name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--name "developer-portal" \
--http-listener apim-developer-listener \
--rule-type Basic \
--address-pool apim-portal \
--http-settings "http-developer" \
--priority 3

# Create WAF policy for the developer portal
DEVELOPER_PORTAL_WAF_POLICY="developer-portal-waf-policies"
az network application-gateway waf-policy create \
--name $DEVELOPER_PORTAL_WAF_POLICY \
--resource-group $RESOURCE_GROUP \
--type OWASP \
--version 3.2

# Enable WAF policy for the developer portal
az network application-gateway waf-policy policy-setting update \
--mode Detection \
--policy-name $DEVELOPER_PORTAL_WAF_POLICY \
--resource-group $RESOURCE_GROUP \
--state Enabled

echo -e "${GREEN} Assign WAF policy to APIM developer listener ${NC}"
az network application-gateway waf-policy update -h