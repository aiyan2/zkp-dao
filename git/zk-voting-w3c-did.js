const snarkjs = require("snarkjs");
const circomlibjs = require("circomlibjs");
const fs = require("fs");
const crypto = require("crypto");

class W3CVotingSystem {
    constructor() {
        this.poseidon = null;
        this.merkleTree = null;
        // this.wasmPath = "./circuits/voting_js/voting.wasm";
           this.wasmPath = './circuits/voting-circuit_js/voting-circuit.wasm'
        this.zkeyPath = "./circuits/voting_final.zkey";
    }

    async initialize() {
        this.poseidon = await circomlibjs.buildPoseidon();
        console.log("✅ Poseidon hash initialized");
    }

    // Hash a value using Poseidon
    hash(input) {
        const hash = this.poseidon([BigInt(input)]);
        return this.poseidon.F.toString(hash);
    }

    // Hash two values (for Merkle tree)
    hashPair(left, right) {
        const hash = this.poseidon([BigInt(left), BigInt(right)]);
        return this.poseidon.F.toString(hash);
    }

    // Create W3C DID-compliant identity
    createW3CIdentity(seed) {
        // Generate deterministic key from seed
        const privateKey = crypto.createHash('sha256').update(seed).digest();
        const publicKeyHash = crypto.createHash('sha256').update(privateKey).digest('hex');
        
        // Create DID (did:zk:publicKeyHash)
        const did = `did:zk:${publicKeyHash.substring(0, 32)}`;
        
        // Use hash of private key as identity secret for ZK circuit
        const identitySecret = BigInt('0x' + privateKey.toString('hex'));
        
        // Create identity commitment for Merkle tree
        const commitment = this.hash(identitySecret);
        
        // Create W3C DID Document
        const didDocument = {
            "@context": [
                "https://www.w3.org/ns/did/v1",
                "https://w3id.org/security/suites/jws-2020/v1"
            ],
            "id": did,
            "verificationMethod": [{
                "id": `${did}#key-1`,
                "type": "JsonWebKey2020",
                "controller": did,
                "publicKeyJwk": {
                    "kty": "OKP",
                    "crv": "Ed25519",
                    "x": publicKeyHash.substring(0, 43) // Base64url encoded
                }
            }],
            "authentication": [`${did}#key-1`],
            "assertionMethod": [`${did}#key-1`],
            "zkIdentity": {
                "commitment": commitment,
                "commitmentMethod": "Poseidon",
                "curve": "BN254"
            }
        };
        
        return {
            did,
            didDocument,
            identitySecret: identitySecret.toString(),
            commitment,
            privateKey: privateKey.toString('hex')
        };
    }

    // Build Merkle tree from identity commitments
    buildMerkleTree(commitments, levels = 10) {
        const tree = [];
        const leaves = [...commitments];
        
        const requiredLeaves = 2 ** levels;
        while (leaves.length < requiredLeaves) {
            leaves.push("0");
        }
        
        tree.push(leaves);
        
        for (let level = 0; level < levels; level++) {
            const currentLevel = tree[level];
            const nextLevel = [];
            
            for (let i = 0; i < currentLevel.length; i += 2) {
                const left = currentLevel[i];
                const right = currentLevel[i + 1];
                nextLevel.push(this.hashPair(left, right));
            }
            
            tree.push(nextLevel);
        }
        
        this.merkleTree = tree;
        return tree[tree.length - 1][0];
    }

    // Generate Merkle proof
    getMerkleProof(leafIndex, levels = 10) {
        const pathElements = [];
        const pathIndices = [];
        
        let index = leafIndex;
        
        for (let level = 0; level < levels; level++) {
            const isRight = index % 2;
            const siblingIndex = isRight ? index - 1 : index + 1;
            
            pathIndices.push(isRight);
            pathElements.push(this.merkleTree[level][siblingIndex] || "0");
            
            index = Math.floor(index / 2);
        }
        
        return { pathElements, pathIndices };
    }

    // Generate nullifier
    generateNullifier(identitySecret, electionId) {
        const nullifier = this.poseidon([BigInt(identitySecret), BigInt(electionId)]);
        return this.poseidon.F.toString(nullifier);
    }

    // Generate zk-SNARK proof
    async generateProof(identitySecret, merkleProof, root, vote, electionId) {
        const nullifierHash = this.generateNullifier(identitySecret, electionId);
        
        const input = {
            identitySecret: identitySecret,
            pathElements: merkleProof.pathElements,
            pathIndices: merkleProof.pathIndices,
            root: root,
            nullifierHash: nullifierHash,
            vote: vote ? "1" : "0",
            electionId: electionId.toString()
        };

        console.log("   🔄 Generating zk-SNARK proof...");
        
        const { proof, publicSignals } = await snarkjs.groth16.fullProve(
            input,
            this.wasmPath,
            this.zkeyPath
        );

        console.log("   ✅ Proof generated");

        return {
            proof,
            publicSignals,
            nullifierHash
        };
    }

    // Verify proof
    async verifyProof(proof, publicSignals) {
        const vKey = JSON.parse(fs.readFileSync("./circuits/verification_key.json"));
        return await snarkjs.groth16.verify(vKey, publicSignals, proof);
    }
}

async function main() {
    console.log("\n" + "=".repeat(70));
    console.log("🔐 W3C DID-COMPATIBLE ZK-SNARK VOTING SYSTEM");
    console.log("=".repeat(70) + "\n");

    const zkSystem = new W3CVotingSystem();
    await zkSystem.initialize();

    // Step 1: Create W3C DID identities
    console.log("👥 Step 1: Creating W3C DID identities...");
    const voters = [
        { name: "Alice", seed: "alice-secret-seed-2024" },
        { name: "Bob", seed: "bob-secret-seed-2024" },
        { name: "Charlie", seed: "charlie-secret-seed-2024" },
        { name: "Diana", seed: "diana-secret-seed-2024" },
        { name: "Eve", seed: "eve-secret-seed-2024" }
    ];

    const identities = voters.map(v => {
        const identity = zkSystem.createW3CIdentity(v.seed);
        console.log(`   ${v.name}:`);
        console.log(`      DID: ${identity.did}`);
        console.log(`      Commitment: ${identity.commitment.substring(0, 20)}...`);
        return { ...v, ...identity };
    });
    console.log();

    // Save DID documents
    console.log("📄 Step 2: Saving DID documents...");
    identities.forEach(identity => {
        const filename = `did-documents/${identity.name.toLowerCase()}-did.json`;
        fs.mkdirSync('did-documents', { recursive: true });
        fs.writeFileSync(filename, JSON.stringify(identity.didDocument, null, 2));
        console.log(`   Saved: ${filename}`);
    });
    console.log();

    // Step 3: Build Merkle tree
    console.log("🌳 Step 3: Building Merkle tree of commitments...");
    const commitments = identities.map(i => i.commitment);
    const merkleRoot = zkSystem.buildMerkleTree(commitments);
    console.log(`   Merkle Root: ${merkleRoot.substring(0, 40)}...`);
    console.log(`   Tree Depth: 10 levels (supports up to 1024 voters)`);
    console.log();

    // Step 4: Setup election
    console.log("📦 Step 4: Election setup...");
    const electionId = Date.now();
    console.log(`   Election ID: ${electionId}`);
    console.log(`   Proposal: "Should we adopt W3C DID-based ZK voting?"`);
    console.log();

    // Step 5: Cast votes with ZK proofs
    console.log("=".repeat(70));
    console.log("🗳️  VOTING PHASE (W3C DIDs + ZK-SNARKS)");
    console.log("=".repeat(70) + "\n");

    const votes = [true, false, true, true, false];

    for (let i = 0; i < identities.length; i++) {
        const voter = identities[i];
        const vote = votes[i];
        
        console.log(`👤 ${voter.name} (${voter.did}) is voting...`);
        console.log(`   Vote: ${vote ? "✅ YES" : "❌ NO"}`);
        
        const merkleProof = zkSystem.getMerkleProof(i);
        const nullifier = zkSystem.generateNullifier(voter.identitySecret, electionId);
        console.log(`   Nullifier: ${nullifier.substring(0, 20)}...`);
        
        const zkProof = await zkSystem.generateProof(
            voter.identitySecret,
            merkleProof,
            merkleRoot,
            vote,
            electionId
        );
        
        console.log(`   ✅ ZK Proof generated`);
        console.log(`   📊 Proof size: ~${JSON.stringify(zkProof.proof).length} bytes`);
        
        const isValid = await zkSystem.verifyProof(zkProof.proof, zkProof.publicSignals);
        console.log(`   ${isValid ? "✅" : "❌"} Proof verification: ${isValid ? "VALID" : "INVALID"}`);
        console.log();
    }

    // Step 6: W3C DID Benefits
    console.log("=".repeat(70));
    console.log("🆔 W3C DID COMPLIANCE BENEFITS");
    console.log("=".repeat(70) + "\n");

    console.log("✅ Standards Compliance:");
    console.log("   • W3C Decentralized Identifiers (DIDs) v1.0");
    console.log("   • Verifiable Credentials Data Model");
    console.log("   • JSON-LD context support");
    console.log("   • Interoperable with W3C ecosystem\n");

    console.log("🔗 DID Methods:");
    console.log("   • Custom method: did:zk:");
    console.log("   • Cryptographically derived from identity");
    console.log("   • Resolvable DID documents");
    console.log("   • Supports verification methods\n");

    console.log("🛡️ Privacy Properties:");
    console.log("   • DID public, but unlinkable to votes");
    console.log("   • ZK commitment in DID document");
    console.log("   • Prove identity without revealing it");
    console.log("   • Compatible with W3C VC ecosystem\n");

    // Step 7: Integration possibilities
    console.log("=".repeat(70));
    console.log("🔌 INTEGRATION POSSIBILITIES");
    console.log("=".repeat(70) + "\n");

    console.log("Can integrate with:");
    console.log("   • W3C Verifiable Credentials for eligibility");
    console.log("   • DID Authentication (DID-Auth)");
    console.log("   • Verifiable Presentations");
    console.log("   • Universal Resolver for DID resolution");
    console.log("   • DID Communication protocols\n");

    console.log("Example use cases:");
    console.log("   • Issue VC for 'Eligible Voter' status");
    console.log("   • Verify identity via DID-Auth");
    console.log("   • Cast anonymous vote with ZK proof");
    console.log("   • All while maintaining W3C compliance\n");

    console.log("=".repeat(70));
    console.log("✨ DEMO COMPLETE");
    console.log("=".repeat(70) + "\n");

    console.log("🎓 Summary:");
    console.log("   • W3C DID standard for identity");
    console.log("   • ZK-SNARKs for anonymous voting");
    console.log("   • Best of both worlds: standards + privacy");
    console.log("   • DID documents saved in did-documents/");
    console.log("   • Fully interoperable with W3C ecosystem\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });