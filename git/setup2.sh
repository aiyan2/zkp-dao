#!/bin/bash

# ZK-SNARK Voting System Setup Script for Ubuntu 22.04/24.04
# This script handles dependency conflicts and automates the entire setup

set -e  # Exit on any error

echo "========================================================================"
echo "🔐 ZK-SNARK VOTING SYSTEM - AUTOMATED SETUP"
echo "========================================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    print_warning "This script is designed for Ubuntu. Proceeding anyway..."
fi

# Step 1: Clean up any conflicting Node.js installations
print_step "Step 1: Cleaning up existing Node.js installations..."
sudo apt-get remove -y nodejs npm node || true
sudo apt-get autoremove -y || true
print_success "Cleanup complete"

# Step 2: Update system and install base dependencies
print_step "Step 2: Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y curl git build-essential pkg-config libssl-dev wget

# Step 3: Install Node.js 18.x using NodeSource
print_step "Step 3: Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
print_success "Node.js installed: $(node -v)"
print_success "npm installed: $(npm -v)"

# Step 4: Install Rust (required for Circom)
print_step "Step 4: Installing Rust..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
    # Also add to current shell
    export PATH="$HOME/.cargo/bin:$PATH"
    print_success "Rust installed: $(rustc --version)"
else
    source "$HOME/.cargo/env" 2>/dev/null || true
    export PATH="$HOME/.cargo/bin:$PATH"
    print_success "Rust already installed: $(rustc --version)"
fi

# Step 5: Install Circom compiler
print_step "Step 5: Installing Circom compiler..."
if ! command -v circom &> /dev/null; then
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://github.com/iden3/circom.git
    cd circom
    cargo build --release
    sudo cargo install --path circom
    cd -
    rm -rf "$TEMP_DIR"
    print_success "Circom compiler installed: $(circom --version)"
else
    print_success "Circom already installed: $(circom --version)"
fi

# Return to project directory
cd "$(dirname "$0")"

# Step 6: Create project structure
print_step "Step 6: Creating project structure..."
mkdir -p circuits contracts scripts
print_success "Project directories created"

# Step 7: Install Node.js dependencies
print_step "Step 7: Installing Node.js dependencies..."
npm install --no-optional
print_success "Node.js dependencies installed"

# Step 8: Install circomlib (circuit libraries)
print_step "Step 8: Installing circomlib..."
if [ ! -d "circomlib" ]; then
    git clone https://github.com/iden3/circomlib.git
    print_success "circomlib installed"
else
    print_success "circomlib already exists"
fi

# Step 9: Compile the circuit
print_step "Step 9: Compiling the voting circuit..."
echo "   This may take a few minutes..."
if [ -f "voting.circom" ]; then
    # Compile the circuit
    circom voting.circom --r1cs --wasm --sym -o circuits/
    
    # Verify the output files were created
    if [ -f "circuits/voting.r1cs" ]; then
        print_success "Circuit compiled successfully"
        echo "   Generated files:"
        ls -lh circuits/voting.r1cs circuits/voting.sym 2>/dev/null | awk '{print "   - " $9 " (" $5 ")"}'
        ls -lh circuits/voting_js/voting.wasm 2>/dev/null | awk '{print "   - " $9 " (" $5 ")"}'
    else
        print_error "Circuit compilation produced no output files!"
        echo "   Expected: circuits/voting.r1cs"
        echo "   Check for compilation errors above."
        exit 1
    fi
else
    print_error "voting.circom not found! Please ensure the file exists."
    exit 1
fi

# Step 10: Download Powers of Tau (trusted setup)
####### build locally
# print_step "Step 10: Downloading Powers of Tau ceremony file..."
# if [ ! -f "powersOfTau28_hez_final_20.ptau" ]; then
#     echo "   Downloading ~288 MB file..."
#     wget -q --show-progress https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_20.ptau || \
#     curl -L -o powersOfTau28_hez_final_20.ptau https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_20.ptau
    
#     # Verify file size (should be around 288 MB)
#     FILE_SIZE=$(stat -f%z "powersOfTau28_hez_final_20.ptau" 2>/dev/null || stat -c%s "powersOfTau28_hez_final_20.ptau" 2>/dev/null)
#     if [ "$FILE_SIZE" -lt 280000000 ]; then
#         print_error "Downloaded file seems incomplete. Please run setup again."
#         exit 1
#     fi
#     print_success "Powers of Tau downloaded ($(du -h powersOfTau28_hez_final_20.ptau | cut -f1))"
# else
#     print_success "Powers of Tau already downloaded"
# fi

cp powersOfTau_final.ptau  powersOfTau28_hez_final_20.ptau

# Step 11: Generate proving and verification keys
print_step "Step 11: Generating proving and verification keys..."
echo "   This may take several minutes..."

# Initial zkey
if [ ! -f "circuits/voting_0000.zkey" ]; then
    npx snarkjs groth16 setup circuits/voting.r1cs powersOfTau28_hez_final_20.ptau circuits/voting_0000.zkey
    print_success "Initial zkey generated"
else
    print_success "Initial zkey already exists"
fi

# Contribute to the ceremony
if [ ! -f "circuits/voting_final.zkey" ]; then
    echo "random entropy for contribution $(date)" | npx snarkjs zkey contribute circuits/voting_0000.zkey circuits/voting_final.zkey --name="1st Contributor"
    print_success "Circuit-specific contribution complete"
else
    print_success "Final zkey already exists"
fi

# Step 12: Export verification key
print_step "Step 12: Exporting verification key..."
npx snarkjs zkey export verificationkey circuits/voting_final.zkey circuits/verification_key.json
print_success "Verification key exported"

# Step 13: Generate Solidity verifier contract
print_step "Step 13: Generating Solidity verifier contract..."
npx snarkjs zkey export solidityverifier circuits/voting_final.zkey contracts/Verifier.sol
print_success "Solidity verifier generated"

# Step 14: Display circuit info
print_step "Step 14: Circuit information..."
npx snarkjs r1cs info circuits/voting.r1cs

echo ""
echo "========================================================================"
echo "✨ SETUP COMPLETE!"
echo "========================================================================"
echo ""
echo "📁 Project Structure:"
echo "   ├── voting-circuit.circom    (Circuit definition)"
echo "   ├── ZKVoting.sol             (Smart contract)"
echo "   ├── zk-voting-demo.js        (Demo script)"
echo "   ├── circuits/                (Compiled circuits)"
echo "   │   ├── voting.r1cs          (Constraint system)"
echo "   │   ├── voting_js/           (WASM prover)"
echo "   │   ├── voting_final.zkey    (Proving key)"
echo "   │   └── verification_key.json"
echo "   └── contracts/"
echo "       ├── Verifier.sol         (Auto-generated verifier)"
echo "       └── ZKVoting.sol         (Voting contract)"
echo ""
echo "🚀 To run the demo:"
echo "   npm run demo"
echo ""
echo "   or"
echo ""
echo "   node zk-voting-demo.js"
echo ""
echo "📝 Notes:"
echo "   • Node.js version: $(node -v)"
echo "   • npm version: $(npm -v)"
echo "   • Circom version: $(circom --version 2>&1 | head -n1)"
echo "   • First proof generation may take 30-60 seconds"
echo "   • Subsequent proofs will be faster (~2-5 seconds)"
echo "   • Requires ~1GB RAM for proof generation"
echo "   • Circuit has 20-level Merkle tree (supports 1M voters)"
echo ""
print_success "Ready to run!"
echo ""
echo "💡 Tip: If you get 'circom: command not found', run:"
echo "   source \$HOME/.cargo/env"