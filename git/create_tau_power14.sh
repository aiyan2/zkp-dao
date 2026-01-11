#!/bin/bash
set -e

echo "=============================================="
echo "🔐 ZK POWERS OF TAU CEREMONY – FULL LOCAL SETUP"
echo "=============================================="
echo ""

POWER=14
CURVE=bn128

# Step 1 – Initialize ceremony
echo "1️⃣  Initializing ceremony..."
snarkjs powersoftau new $CURVE $POWER pot0.ptau -v

# Step 2 – First contribution (you)
echo "2️⃣  Adding your contribution..."
snarkjs powersoftau contribute pot0.ptau pot1.ptau --name="You" -v

# Step 3 – Add entropy from OS randomness
echo "3️⃣  Applying OS randomness..."
snarkjs powersoftau contribute pot1.ptau pot2.ptau --name="SystemEntropy" -v -e="$(head -c 64 /dev/urandom | base64)"

# Step 4 – Beacon (public randomness)
echo "4️⃣  Applying public randomness beacon..."
snarkjs powersoftau beacon pot2.ptau pot3.ptau \
  0102030405060708090a0b0c0d0e0f10 \
  10 \
  -n="Final Beacon"

# Step 5 – Finalize Phase 2
echo "5️⃣  Finalizing Powers of Tau..."
snarkjs powersoftau prepare phase2 pot3.ptau powersOfTau_final.ptau -v

echo ""
echo "✅ DONE"
echo "Generated: powersOfTau_final.ptau"
echo "=============================================="
