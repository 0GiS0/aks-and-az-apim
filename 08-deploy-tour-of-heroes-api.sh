echo -e "${HIGHLIGHT}Deploying sample API to AKS cluster ${AKS_NAME} in ${RESOURCE_GROUP}..."
kubectl create namespace tour-of-heroes-api
kubectl apply -f manifests/tour-of-heroes-api --recursive --namespace tour-of-heroes-api

echo -e "${HIGHLIGHT}Waiting for sample API to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/tour-of-heroes-sql --namespace tour-of-heroes-api

echo -e "${HIGHLIGHT}Done 👍🏻"

echo -e "${HIGHLIGHT} Get internal IP for tour-of-heroes-api service ${NC}"
INTERNAL_IP_API=$(kubectl get service tour-of-heroes-api -n tour-of-heroes-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo -e "${HIGHLIGHT} Test tour of heroes API ${NC}"
kubectl run -it --rm test --image=debian --restart=Never -n tour-of-heroes-api -- bash -c "apt-get update && apt-get install curl -y && curl -k -v http://tour-of-heroes-api/api/hero"
kubectl run -it --rm test --image=debian --restart=Never -n tour-of-heroes-api -- bash -c "apt-get update && apt-get install curl -y && curl -k -v http://${INTERNAL_IP_API}/api/hero"