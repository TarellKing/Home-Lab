TF_DIR ?= terraform/environments/dev

.PHONY: lab-init lab-fmt lab-validate lab-plan lab-up lab-down lab-status docs-tree

lab-init:
	terraform -chdir=$(TF_DIR) init

lab-fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

lab-validate:
	terraform -chdir=$(TF_DIR) validate

lab-plan:
	terraform -chdir=$(TF_DIR) plan

lab-up:
	terraform -chdir=$(TF_DIR) apply

lab-down:
	terraform -chdir=$(TF_DIR) destroy

lab-status:
	terraform -chdir=$(TF_DIR) output

docs-tree:
	find . -maxdepth 4 -type f | sort
