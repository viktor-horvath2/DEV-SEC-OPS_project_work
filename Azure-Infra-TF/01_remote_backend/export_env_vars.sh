#!/bin/bash
#TF_VAR_RG:
echo $(../../terraform show | egrep resource_group_name | tr -d '[:space:]') >> ../02_resources/config.tfbackend
#TF_VAR_SA:
echo $(../../terraform show | egrep storage_account_name | tr -d '[:space:]') >> ../02_resources/config.tfbackend
cd ../02_resources
#TF_VAR_CONT:
echo $(cat ./variables.auto.tfvars | egrep cont | tr -d '[:space:]' | sed "s/backend_container/container_name/") >> ./config.tfbackend
#TF_VAR_KEY:
echo $(cat ./variables.auto.tfvars | egrep key | tr -d '[:space:]' | sed "s/backend_//") >> ./config.tfbackend
