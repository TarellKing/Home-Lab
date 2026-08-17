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
	$(TF) -chdir=$(PLATFORM) init

platform-plan:
	$(TF) -chdir=$(PLATFORM) plan

platform-apply:
	$(TF) -chdir=$(PLATFORM) apply

platform-destroy:
	$(TF) -chdir=$(PLATFORM) destroy

# --- honeynet ---------------------------------------------------------------
honeynet-init:
	$(TF) -chdir=$(HONEYNET) init

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
