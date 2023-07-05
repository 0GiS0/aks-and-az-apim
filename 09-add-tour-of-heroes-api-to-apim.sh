echo -e "${HIGHLIGHT} Create Tour of Heroes API in API Management ${NC}"
az apim api create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--subscription-required true \
--path /tour-of-heroes-api \
--display-name "Tour of Heroes API" \
--service-url "http://tour-of-heroes.${PRIVATE_DNS_ZONE_NAME}/api/hero" \
--protocols http https

echo -e "${HIGHLIGHT} Add GET operation to the API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--url-template / \
--method GET \
--display-name "Get all heroes"

echo -e "${HIGHLIGHT} Add POST operation to the API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--url-template / \
--method POST \
--display-name "Add hero"

echo -e "${GREEN} Add the API to the Starter product ${NC}"
az apim product api add \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--product-id Starter \
--api-id tour-of-heroes-api