## ZK Vault

ZK Vault provides private withdrawals using zero-knowledge proofs. Deposits create commitments included in an on-chain Merkle tree; withdrawals present ZK proofs that a commitment exists and a nullifier is unused to prevent double-spends.

Highlights
- Private withdrawals using zero-knowledge proofs and nullifiers.
- Merkle tree depth: 20 (proofs include 20 sibling nodes).
- Root history: a ring buffer (default 30 roots) — older roots are overwritten as new ones are added.

Repository layout
- `circuit/` – Noir circuit sources and compiled artifacts (`circuit/target/circuit.json`).
- `contracts/` – Solidity contracts and tests (vault, verifier, incremental Merkle tree).
- `contracts/js-scripts/` – helper scripts used by tests (`generate_proof.ts`, `merkle_tree.js`).

Requirements
- Foundry (`forge`) for compiling & running tests.
- Node.js + npm for proof helper scripts (tests call these via `vm.ffi` using `npx tsx`).
- Noir / Barretenberg toolchain to build the circuit and generate the Solidity verifier.

Quickstart
1. Install Foundry and Node.js.
2. Install contract dependencies (recommended Forge flow):

```bash
cd contracts
forge install
cd js-scripts
npm install
```

3. Build the Noir circuit and generate the Solidity verifier

```bash
cd ../../circuit
nargo build --release
bb write_solidity_verifier -k ./target/vk -o ./target/Verifier.sol -t evm
```

4. Compile contracts and run tests

```bash
cd ../contracts
forge build
forge test -vv
```

Running proof helper scripts manually

To debug proof generation directly (outside `vm.ffi`):

```bash
npx tsx contracts/js-scripts/src/generate_proof.ts <nullifier> <secret> <recipient> <leaf1> <leaf2> ...
```

Troubleshooting
- "leaf not found": ensure leaves are provided as 0x-prefixed hex strings — `merkle_tree.js` stores leaves as hex strings and `generate_proof.ts` expects normalized 0x-hex inputs.
- `ProofLengthWrongWithLogN(...)` revert: indicates a prover/verifier mismatch. Regenerate the Solidity verifier from the same circuit artifacts used by the prover (see step 3) and recompile contracts. Add a debug print in `generate_proof.ts` to confirm the generated proof byte length.
- Debug prints from FFI-run scripts may be suppressed by the VM; run the script directly as shown above or write logs to stderr to ensure visibility.

Developer notes
- The circuit uses a Merkle depth of 20. Confirm the on-chain `Verifier.sol` is generated from the same circuit and parameters (LOG_N / N) as the prover.
- The `contracts/js-scripts` helpers normalize hash formats; mismatches between Uint8Array and 0x-hex strings are a common cause of "leaf not found" errors.
 