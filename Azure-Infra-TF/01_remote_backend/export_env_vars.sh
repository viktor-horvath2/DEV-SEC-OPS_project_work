#!/bin/bash
export $(cat ../02_insecure_resources/terraform.tfvars | egrep RG | sed "s/RG/TF_VAR_RG/" | tr -d '[:space:]' | sed "s/\"//g") > ezt módosítani kell a backend-re
export $(cat ../02_insecure_resources/terraform.tfvars | egrep cont | sed "s/backend_container/TF_VAR_CONT/" | tr -d '[:space:]' | sed "s/\"//g")
export $(cat ../02_insecure_resources/terraform.tfvars | egrep key | sed "s/backend_key/TF_VAR_KEY/" | tr -d '[:space:]' | sed "s/\"//g")
TF_VAR_SA=$(terraform show | egrep storage_account_name | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
export TF_VAR_SA