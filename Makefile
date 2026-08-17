# =============================================================================
# Home-Lab honeynet -- two layers, applied in order.
# =============================================================================
#   platform  = persistent (log groups + IAM). You rarely destroy this.
#   honeynet  = disposable (security group + EC2). Tear down freely; logs stay.
#
# Everyday loop:
#   make up            # bring the whole lab online
#   ...attack it, query logs...
#   make down          # kill the EC2/SG, KEEP all logs + history
#   make up            # rebuild -- same log groups, pipeline still works
# =============================================================================

PLATFORM := terraform/layers/platform
HONEYNET := terraform/layers/honeynet
TF := terraform

# State backend lives in S3 (created by terraform/bootstrap). For local use,
# export these first -- they are the same values as the GitHub secrets:
#   export TF_STATE_BUCKET=home-lab-honeynet-tfstate-<acct>-<suffix>
#   export TF_LOCK_TABLE=home-lab-honeynet-tflock
# (`cd terraform/bootstrap && terraform output` prints them.)
AWS_REGION      ?= us-east-1
TF_STATE_BUCKET ?=
TF_LOCK_TABLE   ?=

BACKEND = -backend-config="bucket=$(TF_STATE_BUCKET)" \
          -backend-config="region=$(AWS_REGION)" \
          -backend-config="dynamodb_table=$(TF_LOCK_TABLE)" \
          -backend-config="encrypt=true"

# honeynet reads the platform layer's state; tell it where.
export TF_VAR_platform_state_bucket = $(TF_STATE_BUCKET)
export TF_VAR_aws_region            = $(AWS_REGION)

.PHONY: help fmt validate \
        platform-init platform-plan platform-apply platform-destroy \
        honeynet-init honeynet-plan honeynet-apply honeynet-destroy \
        up down status destroy-all

help:
	@echo "Setup (run once):    make platform-init honeynet-init"
	@echo "Bring lab up:        make up"
	@echo "Tear lab down:       make down        (keeps logs)"
	@echo "Status/outputs:      make status"
	@echo "Nuke everything:     make destroy-all (deletes logs too)"

fmt:
	$(TF) -chdir=$(PLATFORM) fmt -recursive
	$(TF) -chdir=$(HONEYNET) fmt -recursive

validate:
	$(TF) -chdir=$(PLATFORM) validate
	$(TF) -chdir=$(HONEYNET) validate

# --- platform ---------------------------------------------------------------
platform-init:
	$(TF) -chdir=$(PLATFORM) init $(BACKEND) -backend-config="key=honeynet/platform/dev.tfstate"

platform-plan:
	$(TF) -chdir=$(PLATFORM) plan

platform-apply:
	$(TF) -chdir=$(PLATFORM) apply

platform-destroy:
	$(TF) -chdir=$(PLATFORM) destroy

# --- honeynet ---------------------------------------------------------------
honeynet-init:
	$(TF) -chdir=$(HONEYNET) init $(BACKEND) -backend-config="key=honeynet/honeynet/dev.tfstate"

honeynet-plan:
	$(TF) -chdir=$(HONEYNET) plan

honeynet-apply:
	$(TF) -chdir=$(HONEYNET) apply

honeynet-destroy:
	$(TF) -chdir=$(HONEYNET) destroy

# --- convenience ------------------------------------------------------------
# Platform must exist before the honeynet can read its outputs.
up: platform-apply honeynet-apply

# Tears down only the disposable layer. Log groups and history survive.
down: honeynet-destroy

status:
	@echo "=== honeynet ===" && $(TF) -chdir=$(HONEYNET) output || true

# Full teardown, logs included. Order matters: honeynet depends on platform.
destroy-all: honeynet-destroy platform-destroy
