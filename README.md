W3C DID-Compatible ZK-SNARK Voting System

A W3C-standards-compliant anonymous voting system that combines:

Decentralized Identifiers (DIDs)

zk-SNARKs (Groth16)

Merkle commitment trees

Poseidon hashing
to deliver verifiable, unlinkable, privacy-preserving elections.

📁 Repository Structure
File	Purpose
setup2.sh	Circuit compilation + Groth16 trusted setup
create_tau_power14.sh	Generates Powers of Tau locally (offline-friendly)
voting.circom	ZK voting circuit
zk-voting-w3c-did.js	Full DID-compatible voting demo
package.json	Node dependencies
⚙️ Requirements
Tool	Version
Node.js	v20+
npm	latest
circom	v2+
snarkjs	installed via npm
🚀 Quick Start
1️⃣ Generate Powers of Tau
chmod +x create_tau_power14.sh
./create_tau_power14.sh


This produces:

powersOfTau_final.ptau


Rename it:

mv powersOfTau_final.ptau powersOfTau28_hez_final_20.ptau

2️⃣ Build Circuit & Keys
chmod +x setup2.sh
./setup2.sh


This compiles the circuit and generates:

proving key

verification key

wasm witness generator

3️⃣ Install Dependencies
npm install

4️⃣ Run the Demo
node zk-voting-w3c-did.js

🗳️ What Happens

The demo:

Creates W3C-compatible DIDs

Stores commitments in DID Documents (JSON-LD)

Builds a Merkle tree of eligible voters

Generates zk-SNARK proofs for each vote

Verifies all proofs

Prevents double-voting via nullifiers

All while keeping votes anonymous.

🆔 W3C Standards Compliance
Standard	Supported
Decentralized Identifiers (DID v1.0)	✅
Verifiable Credentials Model	✅
JSON-LD Context	✅
DID Authentication Ready	✅
Universal Resolver Compatible	✅
🛡️ Privacy Guarantees
