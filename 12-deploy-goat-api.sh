echo -e "${GREEN}Deploying Goat API to AKS cluster ${AKS_NAME} in ${RESOURCE_GROUP}...${NC}"
kubectl create namespace goat-api
kubectl apply -f manifests/goat-api --recursive --namespace goat-api

# Deploy Traefik using Helm
helm repo add traefik https://traefik.github.io/charts
helm install traefik traefik/traefik --values manifests/traefik-config/values.yaml

echo -e "${GREEN}Waiting for Goat API to be ready...${NC}"
kubectl wait --for=condition=available --timeout=600s deployment/mssql-deployment --namespace goat-api

echo -e "${GREEN}Let's wait 30 seconds for the SQL Server to be ready...${NC}"
sleep 30

kubectl run -it --rm sqlclient --image=mcr.microsoft.com/mssql-tools --restart=Never -n goat-api -- bash -c 'apt-get update && apt-get install curl -y && curl -L https://raw.githubusercontent.com/0GiS0/dotnet-goat-api/main/owaspdb.sql -o owaspdb.sql && /opt/mssql-tools/bin/sqlcmd -S mssql-svc -U sa -P "YourStrong!Passw0rd" -i owaspdb.sql'
# Select Customers table 
kubectl run -it --rm sqlclient --image=mcr.microsoft.com/mssql-tools --restart=Never -n goat-api -- bash -c '/opt/mssql-tools/bin/sqlcmd -S mssql-svc -U sa -P "YourStrong!Passw0rd" -Q "USE owaspdb; SELECT * FROM Customers;"'

echo -e "${GREEN}Done 👍🏻"

echo -e "${GREEN} Get internal IP for goat-api service ${NC}"
INTERNAL_IP_API=$(kubectl get service goat-api-svc -n goat-api -o jsonpath='{.spec.clusterIP}')
# Ingress Controller API
TRAEFIK_IP=$(kubectl get service traefik-web-service -n goat-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo -e "${GREEN} Test Goat API ${NC}"
kubectl run -it --rm test --image=debian --restart=Never -n goat-api -- bash -c "apt-get update && apt-get install curl -y && curl -k -v http://goat-api-svc/customer?id=1"
kubectl run -it --rm test --image=debian --restart=Never -n goat-api -- bash -c "apt-get update && apt-get install curl -y && curl -k -v http://${INTERNAL_IP_API}/customer?id=1"

# Add API to APIM
echo -e "${GREEN} Add Goat API to APIM ${NC}"
az apim api create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id goat-api \
--subscription-required true \
--path /goat \
--display-name "Goat API" \
--service-url "http://goat.${PRIVATE_DNS_ZONE_NAME}" \
--protocols http https

echo -e "${GREEN} Add customer operation to the API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id goat-api \
--url-template "/customer?id={id}" \
--method GET \
--display-name "Get customer" \
--template-parameters name=id description="Customer ID" type="string" required=true

echo -e "${GREEN} Add POST operation to the API ${NC}"
az apim api operation create \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--api-id goat-api \
--url-template /addcreditcard \
--method POST \
--display-name "Add credit card"

# Add api to a starter product
echo -e "${GREEN} Add the API to the Starter product ${NC}"
az apim product api add \
--resource-group ${RESOURCE_GROUP} \
--service-name ${APIM_NAME} \
--product-id Starter \
--api-id goat-api

echo -e "${GREEN} Call customer operation ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.$CUSTOM_DOMAIN/goat/customer?id=1" | jq

echo -e "${GREEN} SQL Injection ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.${CUSTOM_DOMAIN}/goat/customer?id=1%20or%201=1" | jq

echo -e "${GREEN} SQL Injection via HTTPS ${NC}"
curl -k -H "Ocp-Apim-Subscription-Key: ${API_KEY}" "https://api.${CUSTOM_DOMAIN}/goat/customer?id=1%20or%201=1" | jq

echo -e "${GREEN} Add credit card ${NC}"
curl -H "Ocp-Apim-Subscription-Key: ${API_KEY}" -H "Content-Type: application/json" -d '{"id":1,"CardNumber":"1234567890123456","ExpirationDate":"2021-12-31","CVV": "100", "UserId": "1"}' "https://api.${CUSTOM_DOMAIN}/goat/addcreditcard" | jq
