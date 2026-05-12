## zk-mixer

A small Tornado-like mixer using a Noir circuit (Poseidon-based Merkle tree) and an on-chain verifier.

Key ideas
- Privacy-preserving deposits and withdrawals using nullifiers to prevent double-spend.
- Merkle tree depth: 20 (proofs use 20 siblings).
- Root history kept in a ring buffer (default 30 roots) — newer roots overwrite older ones.

Repository layout (important files)
- `circuit/` – Noir circuit sources and compiled artifacts (`circuit/target/circuit.json`).
- `contracts/` – Solidity contracts and tests (mixer, verifier, incremental Merkle tree).
- `contracts/js-scripts/` – helper scripts used by tests (`generate_proof.ts`, `merkle_tree.js`).

Requirements
- Foundry (`forge`) for compiling & running tests.
- Node.js + npm (for proof helper scripts). `npx tsx` is used in tests via `vm.ffi`.
- Noir / Barretenberg toolchain to build the circuit and generate the Solidity verifier.

Quickstart (recommended)
1. Install Foundry: follow Foundry docs, then run `foundryup`.
2. From the repo root, prefer Forge-managed libs:

```bash
# in repo root
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

Running the proof helper script directly

If you need to debug proof generation without `vm.ffi`, run the helper manually:

```bash
npx tsx contracts/js-scripts/src/generate_proof.ts <nullifier> <secret> <recipient> <leaf1> <leaf2> ...
```

Troubleshooting
- "leaf not found": ensure leaves are 0x-prefixed hex strings — `merkle_tree.js` stores leaves as hex strings and `generate_proof.ts` expects normalized 0x-hex strings.
- `ProofLengthWrongWithLogN(...)` revert: indicates a prover/verifier mismatch. Regenerate the Solidity verifier from the same circuit artifact used by the prover (see step 3) and recompile contracts. Print the generated proof length in `generate_proof.ts` to compare against `Verifier.sol` expectations.
- To show debug prints from the FFI-run script, run it directly as above or write logs to stderr (so they aren't suppressed by the VM).

Developer notes
- The Merkle tree in the circuit uses depth 20. The on-chain `Verifier.sol` currently expects `LOG_N = 11` in some configs — make sure the verifier you compile matches the circuit's parameters.
- See `contracts/js-scripts/src/generate_proof.ts` and `contracts/js-scripts/src/merkle_tree.js` for proof generation details and format normalization.

Submodules vs Forge libs
- This repo historically included `contracts/lib/` with submodules. Two options:
      - Use Forge-managed libs: run `cd contracts && forge install` (recommended).
      - If you prefer git submodules, ensure `.gitmodules` is at the repo root and paths point to `contracts/lib/*`, then run `git submodule update --init --recursive`.

If you run into git path errors related to `.gitmodules`, move the file and commit it at the repo root:

```bash
git mv contracts/.gitmodules .gitmodules
git add .gitmodules
git commit -m "Move .gitmodules to repo root"
git submodule update --init --recursive
```

Contact / Contributing
- Open an issue or PR with clear reproduction steps. Include failing test output and a copy of the generated proof bytes if possible.

License
- Project inherits licenses of included libraries; check `contracts/lib` packages for details.

----
This `README.md` aims to make onboarding faster: if you want, I can add a short troubleshooting script or CI job to validate circuit/verifier parity.