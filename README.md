# DevSecOps Internal - Budapest, HU #1 @EPAM
Mentor REQUIREMENTS

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
