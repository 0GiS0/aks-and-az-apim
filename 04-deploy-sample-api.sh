echo -e "${GREEN}Deploying sample API to AKS cluster ${AKS_NAME} in ${RESOURCE_GROUP}..."
kubectl apply -f manifests --recursive

echo -e "${GREEN}Waiting for sample API to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/tour-of-heroes-sql

echo -e "${GREEN}Done 👍🏻"

echo -e "${GREEN} Get internal IP for tour-of-heroes-api service ${NC}"
INTERNAL_IP_API=$(kubectl get service tour-of-heroes-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo -e "${GREEN} Test tour of heroes API ${NC}"
kubectl run -it --rm test --image=debian --restart=Never -- bash -c "apt-get update && apt-get install curl -y && curl -k -v http://tour-of-heroes-api/api/hero"
kubectl run -it --rm test --image=debian --restart=Never -- bash -c "apt-get update && apt-get install curl -y && curl -k -v http://${INTERNAL_IP_API}/api/hero"