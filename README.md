# Ansible Lab — Quick Reference & Notes

Hands-on Ansible practice: provision EC2 with Terraform, manage hosts from inventory, run ad-hoc commands and playbooks. Use this file as your **memory cheat sheet** when you come back to the project.

---

## What lives here

```
ansible/
├── README.md              ← you are here
├── commands.txt           ← raw command list (same ideas, expanded below)
├── inventory2.ini         ← example inventory (manual / lab IPs)
├── playbooks/
│   └── install-web.yml    ← nginx (Ubuntu) + httpd (RedHat)
├── terraform/             ← AWS EC2 + auto-generated inventory/ansible.cfg
│   ├── ec2.tf
│   ├── generate-file.tf
│   └── inventory.tpl / ansible.cfg.tpl
└── .gitignore             ← ignores .terraform/, state, keys (see bottom)
```

**Mental model:** Terraform builds the machines and writes `inventory.ini` + `ansible.cfg`. Ansible talks to those machines using SSH and the inventory.

---

## Install Ansible (control node — usually Ubuntu/WSL)

```bash
sudo apt update
sudo apt install ansible
ansible --version
```

On Windows, run Ansible from **WSL** or a Linux VM/control host — not native PowerShell.

---

## Core concepts (remember these)

| Term | What it means |
|------|----------------|
| **Control node** | Machine where you run `ansible` / `ansible-playbook` (your laptop or WSL). |
| **Managed node** | Remote server Ansible configures (your EC2 workers). |
| **Inventory** | List of hosts + groups + variables (`inventory.ini`, `inventory2.ini`). |
| **Playbook** | YAML file of tasks (e.g. `playbooks/install-web.yml`). |
| **Module** | Built-in action (`ping`, `setup`, `apt`, `dnf`, `service`, …). |
| **Ad-hoc** | One-off command: `ansible … -m <module>`. |
| **`-i`** | Which inventory file to use. |
| **`all`** | Every host in the inventory. |
| **`become: yes`** | Run tasks as root (`sudo`) — needed to install packages. |
| **`setup` module** | Gathers **facts** (OS, IP, memory, …) into `ansible_facts`. |
| **`when:`** | Run a task only if a condition is true (e.g. OS family). |

---

## Inventory (how hosts are grouped)

Example from `inventory2.ini`:

- **`[ubuntu]`** / **`[redhat]`** — OS-specific groups.
- **`[workers:children]`** — parent group; `workers` includes all child groups.
- **`ansible_host`** — IP or DNS Ansible SSHs to.
- **`ansible_user`** — SSH login user (`ubuntu`, `ec2-user`).
- **`ansible_ssh_private_key_file`** — path to private key (in `[all:vars]`).
- **`ansible_python_interpreter`** — Python on the target (Ansible needs it).

Playbook targets **`hosts: workers`** → runs on every host under the `workers` group.

---

## Commands cheat sheet (from `commands.txt`)

### 1. Ping all hosts (connectivity + SSH)

```bash
ansible all -i inventory.ini -m ping
```

**Remember:** Success → `pong`. Failure → check key, security group (port 22), user, and `ansible_host`.

---

### 2. Gather facts (full system info)

```bash
ansible all -i inventory.ini -m setup
```

Dumps JSON facts for each host (OS, network, disks, …). Heavy output — use filters next.

---

### 3. Filter facts — OS family

```bash
ansible all -i inventory.ini -m setup | grep os_family
```

**Remember:** `os_family` is often **`Debian`** (Ubuntu) or **`RedHat`** (Amazon Linux / RHEL). Your playbook uses this in `when:` conditions.

---

### 4. Filter facts — one field only (cleaner)

```bash
ansible all -i inventory.ini -m setup -a "filter=ansible_distribution"
```

**Remember:** `-a` passes **module arguments**. `filter=` limits which facts are returned (faster, easier to read).

Other useful filters: `ansible_os_family`, `ansible_hostname`, `ansible_default_ipv4`.

---

### 5. Run a playbook

```bash
ansible-playbook -i inventory.ini playbooks/install-web.yml
```

**Remember:** Playbooks are idempotent-ish: safe to run again; Ansible only changes what’s needed.

---

## What `install-web.yml` teaches

| Step | Ubuntu (`Debian`) | RedHat |
|------|-------------------|--------|
| Package manager | `apt` (+ `update_cache`) | `dnf` |
| Web server | **nginx** | **httpd** |
| Service | `nginx` started + enabled | `httpd` started + enabled |

Pattern to memorize:

```yaml
when: ansible_facts["os_family"] == "Debian"   # Ubuntu
when: ansible_facts["os_family"] == "RedHat"   # Amazon Linux / RHEL
```

Facts must exist before `when` uses them — the playbook relies on fact gathering (default on play start).

---

## Terraform → Ansible workflow

From `ansible/terraform/`:

```bash
# 1. Configure secrets locally (not in git — see .gitignore)
#    terraform.tfvars: region, keys, server AMIs, etc.

terraform init    # download providers (large — never commit .terraform/)
terraform apply   # create EC2, key pair, security group

# 2. Terraform writes (via generate-file.tf):
#    - inventory.ini
#    - ansible.cfg
```

**Security group (ec2.tf):** SSH **22** and HTTP **80** open for lab access.

**Outputs:** `terraform output` → public/private IPs per server name.

Place your SSH key as `terraform/ansible-key` (private) and register the public key via `public_key_path` in tfvars.

---

## Typical end-to-end session

```bash
# On control node, in project folder
cd terraform && terraform apply && cd ..

ansible all -i inventory.ini -m ping
ansible all -i inventory.ini -m setup -a "filter=ansible_os_family"
ansible-playbook -i inventory.ini playbooks/install-web.yml

# Verify in browser: http://<worker-public-ip>
```

Use `inventory2.ini` instead of `inventory.ini` if you’re on a fixed lab without re-running Terraform:

```bash
ansible all -i inventory2.ini -m ping
```

---

## Troubleshooting (quick)

| Problem | Check |
|---------|--------|
| `UNREACHABLE` | SG port 22, correct IP, key path, `ansible_user` |
| `Permission denied (publickey)` | `ansible_ssh_private_key_file`, key on control node |
| Python errors on target | `ansible_python_interpreter=/usr/bin/python3` |
| Playbook skips tasks | `ansible_facts["os_family"]` — run setup, fix `when:` |
| `git push` fails (large file) | Never commit `.terraform/` — use `.gitignore` |

---

## Git — do not commit

See `.gitignore`:

- `**/.terraform/` (provider binaries ~100MB+)
- `*.tfstate`, `*.tfvars`
- `ansible-key`, `*.pem`

After clone: `cd terraform && terraform init && terraform apply`.

---

## One-line reminders

- **Inventory** = who to talk to. **Playbook** = what to do. **Module** = how to do one thing.
- **`ansible`** = ad-hoc; **`ansible-playbook`** = multi-step automation.
- **`setup`** = facts; **`when`** = OS-specific branches.
- **Terraform** = infrastructure; **Ansible** = configuration on top.

---

*Raw command list: `commands.txt` — this README adds context so you don’t have to relearn it each time.*
