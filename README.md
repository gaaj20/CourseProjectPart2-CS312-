# Course Project Part 2

This project uses scripts that use Ansible and Terraform to automatically set up a Minecraft Java Edition server on AWS. The goal of this project is to provision and configure everything through scripts without manually using the AWS console.

---


## Background

### What this does

The main idea is to create a Minecraft server on AWS and automate all steps using scripts. Three scripts were created to handle everything:

- Terraform: creates the AWS infrastructure (EC2 instance, Elastic IP, security group, key pair)
- Ansible: connects to the instance and installs Java, downloads the Minecraft server JAR, and sets it up as a systemd service
- The server is configured to start on boot and restart if it crashes. It also shuts down cleanly, which was a problem with the previous setup

### How it all fits together

```
Local machine
│
├── scripts/setup.sh        → checks tools, generates SSH key
├── scripts/provision.sh    → runs Terraform, creates AWS resources
├── scripts/configure.sh    → runs Ansible, installs and starts Minecraft
```

---

## Architecture

```
AWS (us-east-1)
└── EC2 t3.medium (Amazon Linux 2023)
    ├── Elastic IP (public IP)
    ├── Security Group (port 25565 open)
    └── systemd: minecraft.service
        ├── Java 21 (Corretto)
        └── Minecraft 1.21.1 server.jar

          ▲ TCP 25565 (Minecraft)
          │
    Players / nmap
```

Why I made my choices:

- **t3.medium** — 2 vCPU and 4 GB RAM are enough to host a small server
- **Elastic IP** — keeps the same public IP even if the instance restarts
- **Amazon Linux 2023** — works well with Amazon Corretto (Java)
- **Ansible instead of user_data** — easier to debug and re-run if something goes wrong

---

## Requirements

### Tools Needed

| Tool | Version | How to install |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.5.0+ | `brew install terraform` |
| [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) | 2.15+ | `pip install ansible` |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | v2 | pip3 install awscli |
| [nmap](https://nmap.org/book/install.html) | 7.x+ | `brew install nmap` / `apt install nmap` |
| `ssh-keygen` | any | Already included on macOS/Linux |

> **On Windows (what I am using):** You'll need WSL2 (https://learn.microsoft.com/en-us/windows/wsl/install) with Ubuntu. All the commands here on this guide are written for a Linux/Mac terminal.

You'll also need Ansible collection:

```bash
ansible-galaxy collection install ansible.posix
```

### AWS Credentials

I built this project using the AWS Academy Learner Lab. To get the credentials I did the following:

1. Open the AWS Learner Lab and start the lab
2. Click **AWS Details** → **Show** next to *AWS CLI*
3. Copy and paste these lines into your terminal (Replace with your credentials):

```bash
aws configure set aws_access_key_id PASTE_YOUR_KEY_HERE

aws configure set aws_secret_access_key PASTE_YOUR_SECRET_HERE

aws configure set aws_session_token PASTE_YOUR_TOKEN_HERE

aws configure set default.region us-east-1
```

> NOTE: These credentials expire after a few hours. If you the terminal gives an `ExpiredTokenException` just go back to AWS Learner Academy and grab the new credentials.

---

## Pipeline Overview

```
setup.sh → provision.sh → configure.sh
   │              │              │
check tools   terraform      ansible
gen SSH key   create EC2     install Java
              create EIP     download JAR
                             start service
                             run nmap

```

## How to Run the Scripts

### 1. Clone the Repo

```bash
git clone https://github.com/<your-username>/CourseProjectPart2-CS312-.git

cd CourseProjectPart2-CS312
```

### 2. Set Up AWS Credentials

Paste your Learner Lab credentials into the terminal as shown above, then verify they work by running:

```bash
aws sts get-caller-identity
```

This should print out your account ID.

### 3. Run Setup

The setup.sh script checks that all tools are installed, generates an SSH key, and creates the Terraform config file.

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

Something like this should output:

```
[INFO]  All required tools found.
[INFO]  Authenticated as AWS account: 123456789012
[INFO]  Generating SSH key pair at /home/user/.ssh/minecraft_key...
[INFO]  Setup complete!
```

### 4. Provision Infrastructure

The provision.sh script runs Terraform and creates everything in AWS.

```bash
./scripts/provision.sh
```

Terraform will show you what it's about to create and ask you to confirm. When it does type "yes". This will about 1-2 minutes. When it is done you'll see the server's public IP printed out.

### 5. Configure the Server

The configure.sh script runs the Ansible playbook, which installs Java 21, downloads the Minecraft JAR, and starts the service.

```bash
./scripts/configure.sh
```

This should take around 3-5 minutes. At the end it automatically runs nmap to confirm the server is up:

```
PORT      STATE SERVICE   VERSION
25565/tcp open  minecraft Minecraft 1.21.1 (Protocol: 127, Message: Acme Corp Minecraft Server, Users: 0/20)
```

> Note: The terminal might output a warning about firewalld during the Ansible run. This is expected and can be ignored because AWS security group handles the firewall.

### 6. Connect to the Server

#### Verify the port is open by running nmap

```bash
nmap -sV -Pn -p T:25565 <your_public_ip>
```

#### Join in Minecraft

1. Open Minecraft Java Edition (1.21.1)
2. Go to "Multiplayer" → "Add Server"
3. Name the server and enter your public IP as the server address
4. Hit "Done" then "Join Server"


## Auto-Restart

The server is set up so that it runs as a systemd service, so it handles a few things automatically:

| Situation | What happens |
|---|---|
| Instance reboots | Server will automatically start back up |
| Server crashes | systemd will restart it after 10 seconds |
| Normal stop (`systemctl stop`) | Sends SIGTERM and waits up to 60 seconds for a clean shutdown |

The clean shutdown was specifically set up to fix the issue with the previous server where it wasn't stopping properly. These configurations now saves the world before exiting.

---

## Troubleshooting

**`ExpiredTokenException`** — your Learner Lab session expired, go get fresh credentials.

**SSH keeps timing out in configure.sh** — the instance is probably still booting. The script will retry for up to 5 minutes on its own. This means you will have to wait.

**nmap shows the port as closed** — Minecraft takes awhile to generate the world on first launch. Wait 60 seconds and try again.

**Firewalld warning during Ansible** — this is fine, the script ignores it intentionally. The security group already handles port access.

---

## Sources

- [Terraform AWS Provider docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible docs](https://docs.ansible.com/)
- [Minecraft server download](https://www.minecraft.net/en-us/download/server)
- [Amazon Corretto 21](https://aws.amazon.com/corretto/)
- [systemd service docs](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)
- [AWS CLI install guide](https://pypi.org/project/awscli/)
- [GitHub markdown syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax)
- [nmap reference](https://nmap.org/book/man.html)
