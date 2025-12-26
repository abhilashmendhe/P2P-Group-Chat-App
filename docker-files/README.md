# Setting Up Docker Image
---
1. Go to the folder where Dockerfile exists.  
<br>
2. Build image with the following command.  
**$** docker build -t . peers:01
<br>
3. Now run the following command to create a docker machine.
**$** docker run -dt --name peer1 \
  -v *\<path\>*:/root/run_scripts \
  -w /root/run_scripts/vms \
  peers:01 \
  bash -c "/root/run_scripts/_1_repo_init/target/debug/repo_init *\<peer-name\>* && tail -f /dev/null"
    <br>
    1. In *\<path\>*, you should provide the group messaging scripts folder path.
    2. In *\<peer-name\>*, you can name any peer you want.

4. To create ssh keygen manually,
**$** ssh-keygen -t ed25519 -C "sshkey" -N ""
<br>
5. Copy content of .pub file from .ssh folder to remote machine in .ssh/authorized_keys file.
<br>
6. To add git remote 
**$** git remote *\<remote-peer-name\>* add ssh://*\<username\>*@*\<IP-ADDR\>*/*\<remote-git-repo-path\>*
    <br>
    1. *\<remote-peer-name\>*: Remote peer name. Anything can set.
    2. *\<username\>*: User of docker linux vm.
    3. *\<IP-ADDR\>*: IP address of the docker vm.
    4. *\<remote-git-repo-path\>*: Path of the peer git repo.
    e.g, 
    **$** git remote add peer2 ssh://root@172.17.0.2/root/scs/peer2
