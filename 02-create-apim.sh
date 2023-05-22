echo "${GREEN}Creating API Management instance..."

time az apim create \
--resource-group ${RESOURCE_GROUP} \
--name ${APIM_NAME} \
--location ${LOCATION} \
--publisher-email "gisela.torres@returngis.net" \
--publisher-name "return(GiS);" \
--sku-name Developer

echo -e "${GREEN}API Management instance created${NC}"