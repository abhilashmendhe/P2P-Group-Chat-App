<img src="./api-logo.png" width="64" style="vertical-align: middle;">
<h1 style="display: inline; vertical-align: middle;">API Specs</h1>

This folder consists of **script based API implementations** our **P2P Group Messaging Application**, written in: 

- 🐚 **Bash** — https://github.com/abhilashmendhe/P2P-Group-Chat-App/tree/main/implementations/bash-script
- 🦀 **Rust** — https://github.com/abhilashmendhe/P2P-Group-Chat-App/tree/main/implementations/rust-script

Each API is exposed as a **CLI script**, allowing users to manage group conversations directly from the terminal.

---

## 📑 API Specification Table

| API            | Description  |
| -------------- | ------------ |
| repo-init      | Initializes the repo which is a starter of our chat app.        |
| create-group   | Creates a group.          |
| add-member     | Adds a member inside a group         |
| remove-member | Removes a member from a group. Members/admins can self-exit. |
| rename-group | Renaming group name and description. |
| promote | Promtes a member to an admin. |
| demote  | Demotes an admin to a normal member. | 
| send_grp_message | Send/Broadcast message in a group. |
| get_group_info | Retrieves group information and messages. |

---

## 🚀 Execution Guide

### 1️⃣ Initialize Repository

**Arguments:**  
- `name`
- `email`

```bash
# 1. In Bash
$ bash-script/01_init_scripts/repo-init.sh "name" "name@gmail.com"

# 2. In Rust
$ rust-scripts/_1_repo_init/target/debug/repo-init "name" "name@gmail.com"
```
### 2️⃣ Create a Group

**Arguments:**  
- `group name`
- `group description`

```bash
# Bash
$ bash-script/03_group_conv/create-group-conv.sh "group-name" "group description ..."

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/create-group "group-name" "group description ..."
```

### 3️⃣ Add a Member

**Arguments:**  
- `group name`
- `member name`

```bash
# Bash
$ bash-script/03_group_conv/add-member-group.sh "group-name" "member-name"

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/add_member "group-name" "member-name"
```

### 4️⃣ Remove a Member

**Arguments:**  
- `group name`
- `member name`

```bash
# Bash
$ bash-script/03_group_conv/rm-member-group.sh "group-name" "member-name"

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/remove_member "group-name" "member-name"
```

### 5️⃣ Rename Group

**Arguments:**  
- `old group name`
- `new group name`
- `new group description (optional)`

```bash
# Bash
$ bash-script/03_group_conv/rename-group.sh "old-group-name" "new-group-name" "new-group-description"

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/rename_group "old-group-name" "new-group-name" "new-group-description"
```

### 6️⃣ Promote Member

**Arguments:**  
- `group name`
- `member name`

```bash
# Bash
$ bash-script/03_group_conv/promote-admin.sh "group-name" "member-name"

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/promote "group-name" "member-name"
```

### 7️⃣ Demote Admin

**Arguments:**  
- `group name`
- `admin name`

```bash
# Bash
$ bash-script/03_group_conv/demote-admin.sh "group-name" "admin-name"

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/demote "group-name" "admin-name"
```

### 8️⃣ Send Message

**Arguments:**  
- `group name`
- `message`

```bash
# Bash
$ bash-script/03_group_conv/send-group-msg.sh "group-name" "-- message --"

# Rust
$ rust-scripts/_2_group_ops_api/target/debug/send_grp_msg "group-name" "-- message --"
```

### 9️⃣ Get Group Info

```bash
# Bash
$ bash-script/03_group_conv/get-group-info.sh

# Rust
$ rust-scripts/scripts/get-group-info.sh
```

---

## ✅ Notes

- All APIs are CLI-based.
- Ensure Bash scripts are executable.
- Build Rust binaries before execution.
