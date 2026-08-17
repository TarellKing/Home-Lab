# Roadmap

## Phase 0 — Foundation

- [x] Terraform project skeleton
- [x] AWS VPC, subnets, routing, security groups
- [x] Central audit bucket
- [x] CloudTrail and VPC Flow Logs
- [x] Public and private EC2 roles
- [x] Makefile workflow

## Phase 1 — Realistic Company Surface

- [ ] Containerized fake CRM
- [ ] Internal API service
- [ ] Synthetic employee/customer documents
- [ ] Structured app logs
- [ ] DNS names that look like a small company

## Phase 2 — Honey Identity and Data

- [ ] Canary IAM access keys with narrow permissions
- [ ] Fake S3 datasets
- [ ] Fake CI/CD artifacts
- [ ] Honey environment files and config files

## Phase 3 — Detection Engineering

- [ ] CloudTrail detections
- [ ] VPC Flow detections
- [ ] App-layer detections
- [ ] Detection tests with known telemetry fixtures

## Phase 4 — Unpredictable Adversarial Activity

- [ ] Randomized attack simulation runners
- [ ] Caldera/Atomic Red Team style exercises where safe
- [ ] Replayable but non-deterministic telemetry generation

## Phase 5 — AI SecOps

- [ ] Investigation runbooks
- [ ] LLM-assisted event summarization
- [ ] Agentic triage workflows with safety boundaries
