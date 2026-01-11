pragma circom 2.1.0;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/mux1.circom";
include "circomlib/circuits/comparators.circom";

// Merkle Tree Proof Verification Circuit
template MerkleTreeChecker(levels) {
    signal input leaf;
    signal input root;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    // Declare all components at template scope
    component hashers[levels];
    component muxLeft[levels];
    component muxRight[levels];

    signal levelHashes[levels + 1];
    levelHashes[0] <== leaf;

    for (var i = 0; i < levels; i++) {
        // Ensure pathIndices is 0 or 1
        pathIndices[i] * (1 - pathIndices[i]) === 0;

        // Initialize components for this level
        hashers[i] = Poseidon(2);
        muxLeft[i] = Mux1();
        muxRight[i] = Mux1();
        
        // Left input: if pathIndices[i] == 0, use levelHashes[i], else use pathElements[i]
        muxLeft[i].c[0] <== levelHashes[i];
        muxLeft[i].c[1] <== pathElements[i];
        muxLeft[i].s <== pathIndices[i];
        
        // Right input: if pathIndices[i] == 0, use pathElements[i], else use levelHashes[i]
        muxRight[i].c[0] <== pathElements[i];
        muxRight[i].c[1] <== levelHashes[i];
        muxRight[i].s <== pathIndices[i];
        
        // Hash the two inputs
        hashers[i].inputs[0] <== muxLeft[i].out;
        hashers[i].inputs[1] <== muxRight[i].out;

        levelHashes[i + 1] <== hashers[i].out;
    }

    // Verify root matches
    root === levelHashes[levels];
}

// Main Voting Circuit
template VotingCircuit(levels) {
    // Private inputs (witnesses)
    signal input identitySecret;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    
    // Public inputs
    signal input root;
    signal input nullifierHash;
    signal input vote; // 0 or 1
    signal input electionId;
    
    // Compute identity commitment
    component identityHasher = Poseidon(1);
    identityHasher.inputs[0] <== identitySecret;
    signal identityCommitment <== identityHasher.out;
    
    // Verify Merkle proof
    component merkleChecker = MerkleTreeChecker(levels);
    merkleChecker.leaf <== identityCommitment;
    merkleChecker.root <== root;
    for (var i = 0; i < levels; i++) {
        merkleChecker.pathElements[i] <== pathElements[i];
        merkleChecker.pathIndices[i] <== pathIndices[i];
    }
    
    // Compute nullifier
    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== identitySecret;
    nullifierHasher.inputs[1] <== electionId;
    nullifierHasher.out === nullifierHash;
    
    // Constrain vote to be 0 or 1
    vote * (vote - 1) === 0;
}

component main {public [root, nullifierHash, vote, electionId]} = VotingCircuit(10);