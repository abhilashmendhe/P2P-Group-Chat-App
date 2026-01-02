# 🚀 MSc Thesis Revision

This _readme_ file consists the task and/or additional work that is needed to be added to my MSc thesis, **_P2P Offline Group Messaging App Based on CRDT_**. These tasks are gathered from my MSc assesment. 

---

1. **Chapter 1 - Introduction**
   
   - [ ] Remove part/section related to _privacy_ and _transparency_ that is unrelated to thesis. 
   - [ ] Remove unwanted _references_ (from bibliography section) that are irrelavant to the introduction part.
   - [ ] Include SpaceX reference link or another example with references
   - [ ] At the end of the indrodution mention about conclusions and related work chapter.

2. **Chapter 2 - Background**
   
   - [ ] Talk about the group memberships of different chat applications that supports group operations. Write about the size of group, the admin removal etc.
   - [ ] Add anti-entropy and gossip protocol theory.
   - [ ] In anti-entopy, discuss, SI model. Push, pull, and push-pull ways.
   - [ ] Add topologies

3. **Chapter 3 - Design**
    Will add extra if any changes are required...

4. **Chapter 4 - Proofs**
   
   - [ ] Add the missing _partial order_ definition related to the sub-parts of the state(Conjunction of partial orders) to (section 4.1.3.1 Definitions; Page 23).
   - [ ] Also refer the _partial order_ definition to monitonicity and LUB. 

5. **Chapter 5 - Implementation**
   
   - [ ] If possible add concurrent diagram and explain them.
     Will add extra if any changes are required..
   - [ ] Talk about the peer address... the pub-key..
   - [ ] Also add git-fetch and git ls-remote when talking about implementsation of programming language. how it is useful..

6. **Chapter 6 - Evaluation**
   
   - [ ] peering context into account where network
     topoplogy (star vs mesh), replication strategy (Gossip vs anti-entropy) and volume of
     transferred data would have been topics to be covered in some way. Instead, we find
     statements like ”For the group size 2048, [storage] just takes 29 Mb. The space acquiring for
     the group size 2048 is very minimal.” (it appears large, to us).
   - [ ] When detailin about network arch, write this
     It's not a full mesh, but a partial mesh + ring backbone—also close to a small-world network.
     Also, write 
     The mesh topology exhibits redundancy in the links and tests the effect of cycles in the synchronization,
     The tree topology represents an optimal propagation scenario over a spanning tree.
      https://www.helloutora.com/post/beyond-basics-mesh-tree-hybrid-topologies
      https://www.researchgate.net/figure/Comparison-of-tree-and-mesh-topologies_tbl1_359056935
      
   - [ ] In discussion, compare groups with the number of blob objects, tree objects, and commit objects. Talk about redundancy
7. **Chapter 7 - Related Work**
   
   - [ ] Adding related work to my MSc thesis. This was considered as a serious omission and neglecting this chapter doesn't adhere to scientific standars.

   
8. **Chapter 8 - Conclusion**
    Will change the conclusion as I change the above chapters.....
   
   - [ ] In future work, talk about when pushing a loarge group state object to a newly added member in the group. (communication overhead..). In git, we can stash the commits, and send a single commit object. Or
   work on pruning techniques. If not using git based app, add the messages on  IPFS or S3 objects, and only send those history of messages required by peer.
   - [ ] Secure CRDTs. (matrix protocol to secure communication). Also talk about how ssh git can secure transfering git objects by connecting git repos by ssh. When talking about ssh, say that it could be unsafe to perform ssh login, so disabling it or create the application in another user profile userspace or into docker vms. 
   - [ ] Talk about byzantine nodes, can change the commit messages.. etc etc.
   - [ ] First talk about in-sufficient public ips for each git repo. One way to optimize is to let have private ip, but use WebRTC (stun, relays) to communicate globally.
   - [ ] Talk about how routing can be added for efficient routing. like kademilia.
   - [ ] Since we making everyone admin when no admin found (churn), we can optimized by making only higly available member that have potentiial to become an admin. Or using ranking function (refer T-MAN paper.)
   When refereing to T-MAN paper, see page 4(distance func.). Also talk about age-based view(page 9), where admin/member churn(leave or join group). Have age-field of each member.


9. Don't forget to add the github link..
