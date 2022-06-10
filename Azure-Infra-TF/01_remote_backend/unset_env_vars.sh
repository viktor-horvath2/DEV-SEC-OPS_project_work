#!/bin/bash
for i in TF_VAR_RG TF_VAR_SA TF_VAR_CONT TF_VAR_KEY
do
	unset $i
done
