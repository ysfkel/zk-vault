import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend, Barretenberg, BackendOptions } from "@aztec/bb.js";
import { Fr } from "@aztec/foundation/curves/bn254";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

export default async function generateCommitment(): Promise<string> {
  try {
    const options: BackendOptions = { threads: 1 };
    const bb = await Barretenberg.new(options);

    const secret = Fr.random();
    const nullifier = Fr.random();

    const commitment = await bb.poseidon2Hash({
      inputs: [
        new Uint8Array(nullifier.toBuffer()),
        new Uint8Array(secret.toBuffer()),
      ],
    });
    const result = ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "bytes32", "bytes32"],
      [commitment.hash, nullifier.toBuffer(), secret.toBuffer()],
    );

    return result;
  } catch (error) {
    console.error("Error generating commitment:", error);
    throw error; // Re-throw the error after logging it
  }
}

(async () => {
  try {
    const commitment = await generateCommitment();
    process.stdout.write(commitment);
    process.exit(0);
  } catch (e) {
    console.error("Error generating commitment:", e);
    process.exit(1);
  }
})();
