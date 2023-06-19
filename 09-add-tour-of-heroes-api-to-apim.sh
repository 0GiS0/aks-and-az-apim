echo -e "${GREEN} Create Tour of Heroes API in API Management ${NC}"
az apim api create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--subscription-required true \
--path /tour-of-heroes-api \
--display-name "Tour of Heroes API" \
--service-url "http://tour-of-heroes.${PRIVATE_DNS_ZONE_NAME}/api/hero" \
--protocols http https

echo -e "${GREEN} Add GET operation to the API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--url-template / \
--method GET \
--display-name "Get all heroes"

echo -e "${GREEN} Add POST operation to the API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id tour-of-heroes-api \
--url-template / \
--method POST \
--display-name "Add hero"