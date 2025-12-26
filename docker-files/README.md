# 🚀 Peer Docker <img src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png" alt="Docker Logo" width="40" height="30" /> and Git <img src="https://git-scm.com/images/logos/downloads/Git-Logo-2Color.png" alt="Git Logo" width="65" /> Setup Guide
</p>

<p align="center">
  <b>Step-by-step guide to build Docker images, run peer containers, and connect them via SSH & Git</b>
</p>

---

## 🧱 Prerequisites

Before you begin, make sure you have:

* ✅ Docker installed
* ✅ Git installed
* ✅ SSH installed (`ssh`, `ssh-keygen`)
* ✅ Group messaging scripts available locally

---

## 📁 Step 1: Navigate to Dockerfile Directory

Go to the directory where your `Dockerfile` exists:

```bash
$ cd path/to/dockerfile
```

---

## 🏗️ Step 2: Build the Docker Image

Build the Docker image using:

```bash
$ docker build -t peers:01 .
```

📌 **Tip:** `peers:01` is the image tag. You can rename it if needed.

---

## 🖥️ Step 3: Run a Peer Container

Create and run a Docker container representing a peer:

```bash
$ docker run -dt --name peer1 \
  -v <path>:/root/run_scripts \
  -w /root/run_scripts/vms \
  peers:01 \
  bash -c "/root/run_scripts/_1_repo_init/target/debug/repo_init <peer-name> && tail -f /dev/null"
```

### 🔧 Parameters Explained

* **`<path>`** → Absolute path to the *group messaging scripts* folder
* **`<peer-name>`** → Any name you want to assign to this peer (e.g. `peer1`, `peerA`)

📦 This command:

* Starts the container in detached mode
* Mounts your scripts into the container
* Initializes a peer-specific git repository
* Keeps the container running

---

## 🔑 Step 4: Generate SSH Keys (Manual)

Inside the container or host machine, generate an SSH key:

```bash
$ ssh-keygen -t ed25519 -C "sshkey" -N ""
```

🔐 This creates:

* Private key → `~/.ssh/id_ed25519`
* Public key → `~/.ssh/id_ed25519.pub`

---

## 📋 Step 5: Configure Authorized Keys

1. Open the public key file:

```bash
$ cat ~/.ssh/id_ed25519.pub
```

2. Copy its contents
3. Paste it into the remote peer’s:

```text
$ ~/.ssh/authorized_keys
```

✅ This enables password-less SSH between peers.

---

## 🌐 Step 6: Add Git Remote Peer

Add a remote Git peer using SSH:

```bash
$ git remote add <remote-peer-name> ssh://<username>@<IP-ADDR>/<remote-git-repo-path>
```

### 🔎 Parameters Explained

* **`<remote-peer-name>`** → Any name for the remote (e.g. `peer2`)
* **`<username>`** → Docker container user (usually `root`)
* **`<IP-ADDR>`** → IP address of the peer container
* **`<remote-git-repo-path>`** → Path to the peer’s Git repository

### ✅ Example

```bash
$ git remote add peer2 ssh://root@172.17.0.2/root/scs/peer2
```

---

## 🧪 Verification

To verify setup:

```bash
$ git remote -v
$ ssh root@<IP-ADDR>
```

If both succeed, your peer setup is complete 🎉

---

## 🧩 Architecture Overview

```text
+---------+        SSH/Git        +---------+
|  Peer1  | <------------------> |  Peer2  |
| Docker  |                      | Docker  |
+---------+                      +---------+
```

---

## 📌 Notes & Best Practices

* Use **static container names** for easier networking
* Consider using **Docker networks** for multi-peer setups
* Backup SSH keys securely

---

<p align="center">
  ⚡ P2P Distributed Sync ⚡
</p>
