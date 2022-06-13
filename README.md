# DevSecOps Internal - Budapest, HU #1 @EPAM
Mentor REQUIREMENTS:

	• Terraform code to deploy resources
		○ Use at least one module from TF registry
		○ Deploy at least one security policy to your environment ( e.g. allow one region only or deny
		unencrypted storage creation)
		○ Deploy at least one serverless function ( e.g. Azure Function, AWS Lambda) to check at least one security related data related to your environment ( e.g. check how many non compliant storage will be after the policy eval) recommended language for the function: Python
	
	• Push your code to remote repository
		○ Master must be protected
		○ Approve your PR to merge your feature branch into master
	• Create Jenkins pipeline (via Jenkins file) which involves (minimum) the following stages:
		1. Plan
		2. Security check
		3. Apply with manual approve


#TERRAFORM SCENARIO:
The SOC submits a request to the cloud infra operations team to create a Linux server for them which they can administer securely. The VM must be reachable from the internet on TCP port 80 as it is going to be configured as a TAXII server which is also hosting a static list of IoCs that can be consumed by the security infrastructure components and devices such as EDR, SIEM, FW and SOAR solutions of business partners.

My Solution:
	1. Created a Service Principal in my pirvate Azure subscription for Terraform. Granted Subscription level write/read/delete permissions to this SP. Terraform uses this SP with certificate based authentication to manage my Azure infrastructure.
	2. Developed an Azure infra in Terraform HCL language. The IaC uses remote state backend also stored in Azure (secured Blob Storage also deployed via TF).
	3. Created a Vagrant based VM environment that uses VirtualBox as provider. My Vagrantifle contains a setup to run the latest LTS Jenkins CI/CD tool from official Docker Hub image. The docker server runs inside an Ubuntu server VM.
	4. Created this public Github repository to represent my achivements and made it available for mentor verification/re-testing and validation purposes.