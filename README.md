
===Files Needed:
1) setup2.sh 
2) zk-voting-w3c-did.js 
3) create_tau_power14.sh ( walk around the download issue)
4) voting.circom 
5) package 

====Steps 
1) ./create_tau_power14.sh   --> output: powersOfTau_final.ptau, rename it to  powersOfTau28_hez_final_20.ptau
2) ./setup2.sh 
3) test@worker:~/zkp/ado$ npm install   --> to install package 
4)  node zk-voting-w3c-did.js --> run the demo

==== output 

test@worker:~/zkp/ado$ node zk-voting-w3c-did.js 
 ````
======================================================================
🔐 W3C DID-COMPATIBLE ZK-SNARK VOTING SYSTEM
======================================================================

✅ Poseidon hash initialized
👥 Step 1: Creating W3C DID identities...
   Alice:
      DID: did:zk:2c2ff2b25e1befc3ad926b5f070643d1
      Commitment: 70646857703904023938...
   Bob:
      DID: did:zk:877f7e6ba9c341824cb9369988d2c990
      Commitment: 77060236029289663840...
   Charlie:
      DID: did:zk:fb2cb7c0f63ed80f4b586aefbb26faff
      Commitment: 14636670233634231755...
   Diana:
      DID: did:zk:176affd370c9982840b6fa7f4041aca3
      Commitment: 12303489685764482133...
   Eve:
      DID: did:zk:485d42dbe42e77bdf4b30b734324dcec
      Commitment: 18891630946839961953...

📄 Step 2: Saving DID documents...
   Saved: did-documents/alice-did.json
   Saved: did-documents/bob-did.json
   Saved: did-documents/charlie-did.json
   Saved: did-documents/diana-did.json
   Saved: did-documents/eve-did.json

🌳 Step 3: Building Merkle tree of commitments...
   Merkle Root: 2050093365206614772245518580982794309788...
   Tree Depth: 10 levels (supports up to 1024 voters)

📦 Step 4: Election setup...
   Election ID: 1768103543944
   Proposal: "Should we adopt W3C DID-based ZK voting?"

======================================================================
🗳️  VOTING PHASE (W3C DIDs + ZK-SNARKS)
======================================================================

👤 Alice (did:zk:2c2ff2b25e1befc3ad926b5f070643d1) is voting...
   Vote: ✅ YES
   Nullifier: 15763453463738654339...
   🔄 Generating zk-SNARK proof...
   ✅ Proof generated
   ✅ ZK Proof generated
   📊 Proof size: ~721 bytes
   ✅ Proof verification: VALID

👤 Bob (did:zk:877f7e6ba9c341824cb9369988d2c990) is voting...
   Vote: ❌ NO
   Nullifier: 98488172448101293371...
   🔄 Generating zk-SNARK proof...
   ✅ Proof generated
   ✅ ZK Proof generated
   📊 Proof size: ~723 bytes
   ✅ Proof verification: VALID

👤 Charlie (did:zk:fb2cb7c0f63ed80f4b586aefbb26faff) is voting...
   Vote: ✅ YES
   Nullifier: 20025055392404631260...
   🔄 Generating zk-SNARK proof...
   ✅ Proof generated
   ✅ ZK Proof generated
   📊 Proof size: ~720 bytes
   ✅ Proof verification: VALID

👤 Diana (did:zk:176affd370c9982840b6fa7f4041aca3) is voting...
   Vote: ✅ YES
   Nullifier: 20514597324996061263...
   🔄 Generating zk-SNARK proof...
   ✅ Proof generated
   ✅ ZK Proof generated
   📊 Proof size: ~724 bytes
   ✅ Proof verification: VALID

👤 Eve (did:zk:485d42dbe42e77bdf4b30b734324dcec) is voting...
   Vote: ❌ NO
   Nullifier: 40044827877790901677...
   🔄 Generating zk-SNARK proof...
   ✅ Proof generated
   ✅ ZK Proof generated
   📊 Proof size: ~724 bytes
   ✅ Proof verification: VALID

======================================================================
🆔 W3C DID COMPLIANCE BENEFITS
======================================================================

✅ Standards Compliance:
   • W3C Decentralized Identifiers (DIDs) v1.0
   • Verifiable Credentials Data Model
   • JSON-LD context support
   • Interoperable with W3C ecosystem

🔗 DID Methods:
   • Custom method: did:zk:
   • Cryptographically derived from identity
   • Resolvable DID documents
   • Supports verification methods

🛡️ Privacy Properties:
   • DID public, but unlinkable to votes
   • ZK commitment in DID document
   • Prove identity without revealing it
   • Compatible with W3C VC ecosystem

======================================================================
🔌 INTEGRATION POSSIBILITIES
======================================================================

Can integrate with:
   • W3C Verifiable Credentials for eligibility
   • DID Authentication (DID-Auth)
   • Verifiable Presentations
   • Universal Resolver for DID resolution
   • DID Communication protocols

Example use cases:
   • Issue VC for 'Eligible Voter' status
   • Verify identity via DID-Auth
   • Cast anonymous vote with ZK proof
   • All while maintaining W3C compliance

======================================================================
✨ DEMO COMPLETE
======================================================================

🎓 Summary:
   • W3C DID standard for identity
   • ZK-SNARKs for anonymous voting
   • Best of both worlds: standards + privacy
   • DID documents saved in did-documents/
   • Fully interoperable with W3C ecosystem

test@worker:~/zkp/ado$ node zk-voting-w3c-did.js  



