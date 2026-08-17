# Home-Lab Honeynet

Infrastructure-as-code for a small, real, internet-facing honeynet in AWS. You
run genuinely vulnerable services, attackers hit them, and the logs land in
CloudWatch where you can build detections on top.

The design goal: **you add or change what the honeypot runs by editing one YAML
file — never Terraform — and you can destroy the expensive parts nightly
without ever losing your logs or breaking the logging pipeline.**

> ⚠️ This lab is deliberately vulnerable. Run it in a **dedicated, non-production
> AWS account** with billing alerts. Never put real secrets, real data, or
> reused passwords anywhere in it.

---

## How it's shaped

Two Terraform layers, applied in order:

| Layer | Lifecycle | Contains |
|-------|-----------|----------|
| **`platform/`** | Persistent — you rarely destroy it | CloudWatch **log groups** (one per service/host log stream) + the honeypot **IAM role/instance profile** |
| **`honeynet/`** | Disposable — tear down anytime | The **security group** and the **EC2 instance(s)** that actually run the honeypots |

Both layers read the same **catalog** (`catalog/*.yaml`). That's what keeps the
firewall rules and the log groups from ever drifting apart, and it's why
`make down` can delete every server while every log group — and all its history
— stays exactly where it was for next time.

```
catalog/
  services.yaml     # WHAT can run: images, ports, weaknesses, log paths
  hosts.yaml        # WHICH boxes exist and which services each runs
services/
  apache-legacy/    # config files that inject each weakness
  ...
terraform/
  modules/catalog/  # parses the YAML (creates no AWS resources)
  layers/platform/  # persistent: log groups + IAM
  layers/honeynet/  # disposable: security group + EC2
```

---

## First run

Prereqs: Terraform ≥ 1.6, AWS CLI configured against a throwaway account, `make`.

```bash
# find your own IP first if you plan to use any "admin"-exposed service
curl -s https://checkip.amazonaws.com

# one-time init
make platform-init
make honeynet-init

# bring the whole lab online
make up

# see what got deployed and what's exposed
make status
```

`make up` applies `platform` then `honeynet`. The EC2 box installs Docker,
pulls the catalog's images, injects the vuln configs, starts everything, and
wires the CloudWatch agent — all from rendered user-data, no manual steps.

Get a shell **without** opening SSH to yourself (port 22 is bait, not your door):

```bash
aws ssm start-session --target <instance_id>
```

---

## The everyday loop

```bash
make up      # lab online
#   ...let it get attacked, query logs in CloudWatch Logs Insights...
make down    # deletes the EC2 box + security group. KEEPS all log groups + history.
make up      # rebuild — same log group names, your saved queries still work
```

`make destroy-all` removes the log groups too, for a clean slate.

---

## Adding a service / making something attackable

Everything below is a **catalog edit + `make honeynet-apply`**. You never touch
a `.tf` file.

### Add a new vulnerable app to an existing box

1. Add an entry to `catalog/services.yaml` (copy an existing one). Set the
   pinned `image`, the `ports` to expose, and the `logs` to capture.
2. If it needs a bad config to be vulnerable, drop the config file under
   `services/<name>/` and list it in `config_mounts`.
3. Add the service key to a host's `services:` list in `catalog/hosts.yaml`.
4. `make platform-apply` (creates its log groups) then `make honeynet-apply`
   (the box rebuilds with the new service). Done.

### Update / bump an image

Change the `image:` tag in `catalog/services.yaml`, then `make honeynet-apply`.
The instance is replaced with the new user-data (~2 min). Because image tags are
always pinned (never `:latest`), your findings stay reproducible.

### Turn a service off but keep its history

Set `enabled: false` in `catalog/services.yaml`. The container stops running;
its log groups and everything already collected stay put.

---

## Where the logs go

- **App stdout/stderr** → shipped straight to CloudWatch by Docker's `awslogs`
  driver → `/honeynet/<env>/service/<service>/stdout`.
- **App log files** (Apache access/error, MySQL query log, …) → bind-mounted to
  the host, tailed by the CloudWatch agent → `/honeynet/<env>/service/<service>/<name>`.
- **Host OS logs** (`messages`, `secure`, `cloud-init`, `audit`) →
  `/honeynet/<env>/host/<host>/<stream>`.

All of these are the persistent log groups in the `platform` layer, so they
outlive any teardown. Point a real SIEM (Splunk/Elastic/OpenSearch) at them
later via a CloudWatch subscription filter — the group names never change.

---

## What's intentionally not here yet

Deferred to keep the MVP small — natural next steps, not gaps:

- **Deploy from GitHub Actions.** Runs locally for now (`terraform apply` from
  your laptop, state in the layer directories). Adding CI later means an S3
  state backend + a GitHub OIDC role; nothing else changes.
- **A dedicated isolated VPC.** The MVP uses your account's default VPC. The
  `data-01` internal DB tier in `hosts.yaml` is scaffolded (`enabled: false`)
  for when you want a lateral-movement target in its own network.
- **CloudTrail / cloud-attack telemetry and SIEM fan-out.** CloudWatch is the
  SIEM for now.
