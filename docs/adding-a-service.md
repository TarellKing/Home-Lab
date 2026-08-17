# Adding a service (worked example: a database)

Everything a honeypot runs is declared in `catalog/`. Adding a service is a
**YAML edit + apply** — you never touch a `.tf` file. This walks through adding a
PostgreSQL database an attacker can hit, then generalizes.

> TL;DR
> ```bash
> ./scripts/new-service.sh my-service   # scaffolds services/my-service/ + prints a catalog stub
> # edit catalog/services.yaml + catalog/hosts.yaml
> make validate && make platform-apply && make honeynet-apply
> ```

---

## What a service entry controls

One entry in `catalog/services.yaml` drives all of this automatically:

| You declare | You get |
|-------------|---------|
| `image` | the container that runs |
| `ports` | the published port **and** the security-group rule (per `exposure`) |
| `logs` | a persistent CloudWatch log group + a bind mount + an agent tail rule |
| `config_mounts` | your bad config file injected into the container (the weakness) |
| `env`, `command` | how the container starts |

Then you list the service under a host in `catalog/hosts.yaml`. That's it.

---

## Worked example — PostgreSQL with no password

This is already in the catalog as `postgres-trust-auth` (attached to the
`data-01` host, which ships `enabled: false`). Here's how it was built and how to
turn it on.

### 1. The service entry (`catalog/services.yaml`)

```yaml
  postgres-trust-auth:
    enabled: true
    description: "PostgreSQL 15 with host_auth_method=trust. No password required."
    image: postgres:15.6                      # pinned — never :latest
    weakness:
      class: misconfig
      notes: "trust auth = any client on the port is the superuser, no password."
    ports:
      - { container: 5432, host: 5432, protocol: tcp, exposure: internal }
    logs: []                                   # Postgres logs to stdout -> the forwarder grabs it
    env:
      POSTGRES_HOST_AUTH_METHOD: "trust"       # the misconfiguration
      POSTGRES_DB: "customers"
    command: ["postgres", "-c", "log_connections=on", "-c", "log_statement=all"]
```

**`exposure` is the key decision:**

- `internal` — reachable only from other honeynet hosts. This models a database
  an attacker reaches **after** pivoting from the compromised web edge
  (lateral movement). Most realistic; less raw traffic.
- `public` — `0.0.0.0/0`. The classic "exposed database on the internet" that
  scanners find within minutes. Change the one word to `public` if you want
  direct attacker interaction fast.
- `admin` — only your `admin_cidr`, for testing.

### 2. Attach it to a host (`catalog/hosts.yaml`)

```yaml
  data-01:
    enabled: true          # flip to true to actually deploy the DB tier
    subnet: private
    services:
      - postgres-trust-auth
```

`enabled: true` on the host is what makes the EC2 box exist. Leaving it `false`
still creates the log groups (so history is ready), just no running box.

### 3. Validate, then deploy

```bash
make validate          # catalog schema checks — typos, bad exposure, port clashes, unpinned images all fail HERE
make platform-apply    # creates the log groups for any file logs you declared
make honeynet-apply    # (re)builds the host(s) with the new service
```

Or deploy through GitHub Actions (`gh workflow run deploy.yml -f action=apply`).

### 4. Watch the attacker

```bash
# connect the way an attacker would (no password):
psql "host=<host-ip> port=5432 user=postgres dbname=customers" -c "select version();"
```

- Container stdout (every connection + statement, via `log_connections` /
  `log_statement`) → **Datadog** (the agent's container-log collection).
- Any file logs you declared → **CloudWatch** at
  `/honeynet/<env>/service/<service>/<name>`.

---

## Injecting a weakness that needs a config file

Some services need a bad config file, not just env vars (Apache's `httpd.conf`,
Redis's `redis.conf`, MySQL's `my.cnf`). Two steps:

1. Put the file under `services/<service>/` (the scaffold script makes the dir).
2. Reference it with `config_mounts`:

```yaml
    config_mounts:
      - { file: postgresql.conf, target: /etc/postgresql/postgresql.conf }
```

The file is synced to the host and bind-mounted read-only into the container.

---

## The guardrails (why typos fail early)

`make validate` runs the catalog's schema checks. It fails the plan — before
anything is built — if you:

- reference a service from a host that doesn't exist,
- use an `exposure` other than `public` / `admin` / `internal` / `none`,
- put two services on the same host fighting over one host port,
- or pin an image to `:latest` (findings must stay reproducible).

So the fast loop is: edit YAML → `make validate` → fix messages → apply.

---

## Quick reference: exposure vs. what it opens

| `exposure` | Security-group source | Use for |
|------------|-----------------------|---------|
| `public`   | `0.0.0.0/0`           | internet bait (web, exposed DB honeypot) |
| `admin`    | your `admin_cidr`     | something only you should reach |
| `internal` | the VPC CIDR          | lateral-movement target (DB behind the web tier) |
| `none`     | *(no rule)*           | published on the host, reachable only on-box |
