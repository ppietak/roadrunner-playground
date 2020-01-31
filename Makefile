build:
	docker build -t roadrunner-lambda .
	rm app.zip | true
	docker run --rm -v $(PWD)/tmp:/tmp roadrunner-lambda cp app.zip /tmp



terraform-plan:
	cd terraform && terraform plan -var-file=vars/$(ENV).tfvars -out=apply.tfplan

terraform-apply:
	cd terraform && terraform apply apply.tfplan
