#!/bin/bash
#TF_VAR_RG:
../../terraform show | egrep resource_group_name | sed s/'\s'//g | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" >> ../02_resources/config.tfbackend
#TF_VAR_SA:
../../terraform show | egrep storage_account_name | sed s/'\s'//g | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" >> ../02_resources/config.tfbackend
cd ../02_resources
#TF_VAR_CONT:
echo $(cat ./variables.auto.tfvars | egrep cont | tr -d '[:blank:]' | sed "s/backend_container/container_name/") >> ./config.tfbackend
#TF_VAR_KEY:
echo $(cat ./variables.auto.tfvars | egrep key | tr -d '[:blank:]' | sed "s/backend_//") >> ./config.tfbackend
