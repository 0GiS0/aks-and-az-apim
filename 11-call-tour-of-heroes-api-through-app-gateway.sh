# Get subscription id
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get starter API Key
API_KEY=$(az rest --method get \
--uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ApiManagement/service/${APIM_NAME}/subscriptions?api-version=2018-01-01" \
| jq --raw-output '.value[] | select(.properties.productId | endswith("starter")) | .properties.primaryKey')

echo -e "${GREEN} Test tour of heroes API ${NC}"

echo -e "${GREEN} Get heroes ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.${CUSTOM_DOMAIN}/tour-of-heroes-api/" | jq

echo -e "${GREEN} Add hero ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" \
-H "Content-Type: application/json" \
-X POST \
-d '{"name": "Arrow", "alterEgo": "Oliver Queen", "description": "Multimillonario playboy Oliver Queen (Stephen Amell), quien, cinco años después de estar varado en una isla hostil, regresa a casa para luchar contra el crimen y la corrupción como un vigilante secreto cuya arma de elección es un arco y flechas." }' \
"https://api.${CUSTOM_DOMAIN}/tour-of-heroes-api/"

echo -e "${GREEN} Get heroes ${NC}"
curl -k -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.$CUSTOM_DOMAIN/tour-of-heroes-api/" | jq
curl -k -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.${CUSTOM_DOMAIN}/tour-of-heroes-api/" | jq


echo -e "${GREEN} Get heroes using HTTPS ${NC}"
curl -k -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.$CUSTOM_DOMAIN/tour-of-heroes-api/" | jq