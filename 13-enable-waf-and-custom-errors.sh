echo -e "${GREEN}Create Azure Storage Account"
az storage account create \
--name $STORAGE_ACCOUNT_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION

echo -e "${GREEN}Enable static website"
az storage blob service-properties update \
--account-name $STORAGE_ACCOUNT_NAME \
--static-website

echo -e "${GREEN}Get static website url for custom error pages"
STATIC_WEB_SITE_URL=$(az storage account show \
--name $STORAGE_ACCOUNT_NAME \
--resource-group $RESOURCE_GROUP \
--query primaryEndpoints.web \
--output tsv)

echo -e "${GREEN}Upload custom error pages"
az storage blob upload-batch \
--account-name $STORAGE_ACCOUNT_NAME \
--destination \$web \
--source custom-error-pages

echo -e "${GREEN}Update App Gw to use custom error pages"
az network application-gateway update \
--name $APP_GW_NAME \
--resource-group $RESOURCE_GROUP \
--custom-error-pages 403="$STATIC_WEB_SITE_URL/403.html" 502="$STATIC_WEB_SITE_URL/502.html"

echo -e "${GREEN}Change WAF policy mode to prevention${NC}"
az network application-gateway waf-policy policy-setting update \
--mode Prevention \
--policy-name $GENERAL_WAF_POLICY \
--resource-group $RESOURCE_GROUP \
--state Enabled

echo -e "${GREEN}Check APIs${NC}"
echo "http://${APP_GW_PUBLIC_IP}/tour-of-heroes-api/?subscription-key=${API_KEY}"
echo "https://${APP_GW_PUBLIC_IP}/goat/customer?id=1&subscription-key=${API_KEY}"
echo "https://${APP_GW_PUBLIC_IP}/goat/customer?subscription-key=${API_KEY}&id=1%20or%201=1"