<img src="./api-logo.png" width="64" style="vertical-align: middle;">
<h1 style="display: inline; vertical-align: middle;">API Specs</h1>

This folder consists of implementations of our group messaging app in both [Bash](https://github.com/abhilashmendhe/P2P-Group-Chat-App/tree/main/implementations/bash-script) and [Rust](https://github.com/abhilashmendhe/P2P-Group-Chat-App/tree/main/implementations/rust-script).

These apis are in the form of scripts.

---

## Specification Table

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

## Execution

1. Initializing a repo. It takes two arguments, name and an email.

```bash
# 1. In Bash
$ bash-script/01_init_scripts/repo-init.sh "name" "name@gmail.com"

# 2. In Rust
$ rust-scripts/_1_repo_init/target/debug/repo-init "name" "name@gmail.com"
```

2. Creating a group which takes two arguments, group name and description.

```bash
# 1. In Bash
$ bash-script/03_group_conv/create-group-conv.sh "group-name" "group description ..."

# 2. In Rust
$ rust-scripts/_2_group_ops_api/target/debug/create-group "group-name" "group description ..."
```

3. Add a member inside a group. It takes 2 arguments group name and the name of the member.

```bash
# 1. In Bash
$ bash-script/03_group_conv/add-member-group.sh "group-name" "member-name"

# 2. In Rust
$ rust-scripts/_2_group_ops_api/target/debug/add_member "group-name" "member-name"
```

4. Remove a member from a group. It takes 2 arguments group name and the name of the member.

```bash
# 1. In Bash (to remove others)
$ bash-script/03_group_conv/rm-member-group.sh "group-name" "other-member-name"

# 2. In Bash (to remove self)
$ bash-script/03_group_conv/rm-member-group.sh "group-name" "self-name"

# 3. In Rust (to remove others)
$ rust-scripts/_2_group_ops_api/target/debug/remove_member "group-name" "other-member-name"

# 4. In Rust (to remote self)
$ rust-scripts/_2_group_ops_api/target/debug/remove_member "group-name" "self-name"
```

5. Renaming a group and it's description. It takes 3 arguments old group name, new group name and the new group description.

```bash
# 1. In Bash
$ bash-script/03_group_conv/rename-group.sh "old-group-name" "new-group-name" "new-group-description"

# 2. In Rust
$ rust-scripts/_2_group_ops_api/target/debug/rename_group "old-group-name" "new-group-name" "new-group-description"
```

6. Promoting a member. It takes 2 arguments group name, and a member name.

```bash
# 1. In Bash
$ bash-script/03_group_conv/promote-admin.sh "group-name" "member-name"

# 2. In Rust
$ rust-scripts/_2_group_ops_api/target/debug/promote "group-name" "member-name"
```

7. Demoting a member. It takes 2 arguments group name, and a admin name.

```bash
# 1. In Bash
$ bash-script/03_group_conv/demote-admin.sh "group-name" "admin-name"

# 2. In Rust
$ rust-scripts/_2_group_ops_api/target/debug/demote "group-name" "admin-name"
```

8. Sending or broadcasting a message in a group. It takes 2 arguments, group name and a message.

```bash
# 1. In Bash
$ bash-script/03_group_conv/send-group-msg.sh "group-name" "-- message --"

# 2. In Rust
$ rust-scripts/_2_group_ops_api/target/debug/send_grp_msg "group-name" "-- message --"
```

9. Get group information.

```bash
# 1. In Bash
$ bash-script/03_group_conv/get-group-info.sh

# 2. In Rust
$ rust-scripts/scripts/get-group-info.sh
```
