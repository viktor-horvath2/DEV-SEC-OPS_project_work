#!/bin/bash
TF_VAR_RG=$(../../terraform show | egrep resource_group_name | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
TF_VAR_SA=$(../../terraform show | egrep storage_account_name | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
cd ../02_resources
TF_VAR_CONT=$(cat ./variables.auto.tfvars | egrep cont | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
TF_VAR_KEY=$(cat ./variables.auto.tfvars | egrep key | tr -d '[:space:]' | tr '=' ' ' | awk '{print$2}' | sed "s/\"//g")
