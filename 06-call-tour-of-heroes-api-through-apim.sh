# Add api to a starter product
echo -e "${GREEN} Add the API to the Starter product ${NC}"
az apim product api add \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--product-id Starter \
--api-id tour-of-heroes-api

# Get starter API Key
API_KEY=$(az rest --method get \
--uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/subscriptions?api-version=2018-01-01" \
| jq '.value[] | select(.properties.productId | endswith("starter")) | .properties.primaryKey')

echo -e "${GREEN} Test tour of heroes API ${NC}"

echo -e "${GREEN} Get heroes ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "http://${APIM_NAME}.azure-api.net/tour-of-heroes-api/" | jq

echo -e "${GREEN} Add hero ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
-H "Content-Type: application/json" \
-X POST \
-d '{"name": "Arrow", "alterEgo": "Oliver Queen", "description": "Multimillonario playboy Oliver Queen (Stephen Amell), quien, cinco años después de estar varado en una isla hostil, regresa a casa para luchar contra el crimen y la corrupción como un vigilante secreto cuya arma de elección es un arco y flechas." }' \
"http://${APIM_NAME}.azure-api.net/tour-of-heroes-api/"

echo -e "${GREEN} Get heroes ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "http://${APIM_NAME}.azure-api.net/tour-of-heroes-api/" | jq