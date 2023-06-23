echo -e "${HIGHLIGHT}Creating an identity for AKS...${NC}"
az identity create \
--resource-group ${RESOURCE_GROUP} \
--name ${AKS_NAME}-identity

echo -e "${HIGHLIGHT}Waiting 60 seconds for the identity...${NC}"
sleep 60
IDENTITY_ID=$(az identity show --name $AKS_NAME-identity --resource-group $RESOURCE_GROUP --query id -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name $AKS_NAME-identity --resource-group $RESOURCE_GROUP --query clientId -o tsv)

# Get VNET id
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query id -o tsv)

# Assign Network Contributor role to the user identity
echo -e "${HIGHLIGHT}Assign roles to the identity...${NC}"
az role assignment create --assignee $IDENTITY_CLIENT_ID --scope $VNET_ID --role "Network Contributor"
# Permission granted to your cluster's managed identity used by Azure may take up 60 minutes to populate.

# Get roles assigned to the user identity
az role assignment list --assignee $IDENTITY_CLIENT_ID --all -o table

AKS_SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $AKS_SUBNET_NAME --query id -o tsv)

echo -e "${HIGHLIGHT}Creating AKS cluster ${AKS_NAME} in ${RESOURCE_GROUP}...${NC}"
time az aks create \
--resource-group ${RESOURCE_GROUP} \
--name ${AKS_NAME} \
--node-vm-size Standard_B4ms \
--enable-managed-identity \
--vnet-subnet-id $AKS_SUBNET_ID \
--assign-identity $IDENTITY_ID \
--enable-addons monitoring \
--generate-ssh-keys

echo -e "${HIGHLIGHT}Getting AKS credentials...${NC}"
az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_NAME} --overwrite-existing

echo -e "${HIGHLIGHT}Fetching the kubelet identity...${NC}"
KUBELET_IDENTITY_CLIENT_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "identityProfile.kubeletidentity.objectId" --output tsv)

echo -e "${HIGHLIGHT}Assign the 'Reader' and 'DNS Zone Contributor' role...${NC}"
az role assignment create --role "Reader" --assignee $KUBELET_IDENTITY_CLIENT_ID --scope $RESOURCE_GROUP_ID
az role assignment create --role "Private DNS Zone Contributor" --assignee $KUBELET_IDENTITY_CLIENT_ID --scope $PRIVATE_DNS_ZONE_ID


echo -e "${HIGHLIGHT}Create a configuration file for the identity...${NC}"
cat <<EOF > azure.json
{
    "tenantId": "$(az account show --query tenantId -o tsv)",
    "subscriptionId": "$(az account show --query id -o tsv)",
    "resourceGroup": "$RESOURCE_GROUP",
    "useManagedIdentityExtension": true
}
EOF

echo -e "${HIGHLIGHT}Create a secret for the identity...${NC}"
kubectl create secret generic azure-config-file --from-file=azure.json

echo -e "${HIGHLIGHT}Deploy ExternalDNS for Azure Private DNS...${NC}"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns-private
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
  - apiGroups: [""]
    resources: ["services","endpoints","pods", "nodes"]
    verbs: ["get","watch","list"]
  - apiGroups: ["extensions","networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer-private
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
  - kind: ServiceAccount
    name: external-dns-private
    namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns-private
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns-private
  template:
    metadata:
      labels:
        app: external-dns-private
    spec:
      serviceAccountName: external-dns-private
      containers:
        - name: external-dns-private
          image: registry.k8s.io/external-dns/external-dns:v0.13.4
          args:
            - --source=service
            - --source=ingress
            # - --domain-filter=$PUBLIC_DNS_ZONE_NAME # (optional)
            - --provider=azure-private-dns
            - --azure-resource-group=$RESOURCE_GROUP # (optional) 
            - --txt-prefix=externaldns-
            - --publish-internal-services
          volumeMounts:
            - name: azure-config-file
              mountPath: /etc/kubernetes
              readOnly: true
      volumes:
        - name: azure-config-file
          secret:
            secretName: azure-config-file
EOF

# Wait for external-dns to be ready
kubectl wait --for=condition=available --timeout=600s deployment/external-dns-private

echo -e "${HIGHLIGHT}ExternalDNS deployed!${NC}"