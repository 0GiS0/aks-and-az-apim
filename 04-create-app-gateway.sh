echo "${HIGHLIGHT}Creating Application Gateway...${NC}"

# Create public ip
az network public-ip create \
--resource-group $RESOURCE_GROUP \
--name $APP_GW_PUBLIC_IP_NAME \
--allocation-method Static \
--sku Standard \
--dns-name $APP_GW_PUBLIC_IP_DNS_NAME

# Create a WAF policy
GENERAL_WAF_POLICY="general-waf-policies"
az network application-gateway waf-policy create \
--name $GENERAL_WAF_POLICY \
--resource-group $RESOURCE_GROUP \
--type OWASP \
--version 3.2

# Get WAF policy ID
WAF_POLICY_ID=$(az network application-gateway waf-policy show --name $GENERAL_WAF_POLICY --resource-group $RESOURCE_GROUP --query id -o tsv)

# Create the app gateway
time az network application-gateway create \
--resource-group $RESOURCE_GROUP \
--name $APP_GW_NAME \
--location $LOCATION \
--vnet-name $VNET_NAME \
--subnet $APP_GW_SUBNET_NAME \
--public-ip-address $APP_GW_PUBLIC_IP_NAME \
--sku WAF_v2 \
--capacity 1 \
--priority 1 \
--waf-policy $GENERAL_WAF_POLICY

APP_GW_ID=$(az network application-gateway show --name $APP_GW_NAME --resource-group $RESOURCE_GROUP --query id -o tsv)

echo -e "${HIGHLIGHT}Application Gateway created${NC}"

echo -e "${HIGHLIGHT}Create workspace for diagnostics${NC}"
WORKSPACE_ID=$(az monitor log-analytics workspace create \
--resource-group $RESOURCE_GROUP \
--workspace-name $APP_GW_NAME-workspace \
--location $LOCATION \
--query id -o tsv)

echo -e "${HIGHLIGHT}Enable diagnostics settings${NC}"
az monitor diagnostic-settings create \
--name $APP_GW_NAME-diag \
--resource $APP_GW_ID \
--resource-group $RESOURCE_GROUP \
--workspace $WORKSPACE_ID \
--logs '[
  {
    "category": "ApplicationGatewayAccessLog",
    "enabled": true,
    "retentionPolicy": {
      "enabled": false,
      "days": 0
    }
  },
  {
    "category": "ApplicationGatewayPerformanceLog",
    "enabled": true,
    "retentionPolicy": {
      "enabled": false,
      "days": 0
    }
  },
  {
    "category": "ApplicationGatewayFirewallLog",
    "enabled": true,
    "retentionPolicy": {
      "enabled": false,
      "days": 0
    }
  }
]'