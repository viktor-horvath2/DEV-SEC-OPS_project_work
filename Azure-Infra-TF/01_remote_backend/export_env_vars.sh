#!/bin/bash
cd ../01_remote_backend
TF_VAR_RG=$(../../terraform show | egrep resource_group_name | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
TF_VAR_SA=$(../../terraform show | egrep storage_account_name | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
export TF_VAR_SA
export TF_VAR_RG
export $(cat ./variables.auto.tfvars | egrep cont | sed "s/backend_container/TF_VAR_CONT/" | tr -d '[:space:]' | sed "s/\"//g")
export $(cat ./variables.auto.tfvars | egrep key | sed "s/backend_key/TF_VAR_KEY/" | tr -d '[:space:]' | sed "s/\"//g")
