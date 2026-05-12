import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend, Barretenberg, BackendOptions } from "@aztec/bb.js";
import { Fr } from "@aztec/foundation/curves/bn254";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";
import { merkleTree } from "./merkle_tree.js";

const cicuitPath = path.resolve(
  __dirname,
  "../../../circuit/target/circuit.json",
);
const circuit = JSON.parse(fs.readFileSync(cicuitPath, "utf8"));

export default async function generateProof(): Promise<any> {
  const inputs = process.argv.slice(2);

  try {
    const noir = new Noir(circuit);
    const options: BackendOptions = { threads: 1 };
    const bb = await Barretenberg.new(options);
    const bk = new UltraHonkBackend(circuit.bytecode, bb);

    // Parse the inputs from the command line arguments
    const nullifier = Fr.fromString(inputs[0]);
    const secret = Fr.fromString(inputs[1]);
    const recipient = inputs[2];
    const leaves = inputs.slice(3); //inputs.slice(3).map((leaf: string) => Fr.fromString(leaf));

    const nullifier_hash = await bb.poseidon2Hash({
      inputs: [new Uint8Array(nullifier.toBuffer())],
    });
    const commitment = await bb.poseidon2Hash({
      inputs: [
        new Uint8Array(nullifier.toBuffer()),
        new Uint8Array(secret.toBuffer()),
      ],
    });
    const tree = await merkleTree(leaves);

    const commitmentHex = getHexString(commitment.hash);
    const merkleProof = tree.proof(tree.getIndex(commitmentHex));

    const input = {
      // public input
      root: merkleProof.root.toString(),
      nullifier_hash: getHexString(nullifier_hash.hash), // the address of the user making the guess, passed as a public input to the circuit to prevent it from being optimized out during compilation
      recipient: recipient,

      // private input
      nullifier: nullifier.toString(),
      secret: secret.toString(),
      merkle_proof: merkleProof.pathElements.map((el: any) => el.toString()),
      is_even: merkleProof.pathIndices.map((i: number) =>
        i % 2 === 0
      ), // convert path indices to binary format expected by the circuit where 1 represents left and 0 represents right
    };

    // Generate witness and return value by executing the circuit with the provided inputs
    const { witness } = await noir.execute(input);

    // suppress console logs from the backend during proof generation to prevent logs from being returned as part of foundry ffi output

    const originalConsoleLog = console.log; // first store the original console.log function
    console.log = () => {}; // then override console.log to a no-op function to suppress logs

    // Generate the proof using the witness
    const proofdata = await bk.generateProof(witness, {
      verifierTarget: "evm",
    });
    bk.verifyProof(proofdata); // verify the proof before returning it to ensure it's valid
    const { proof, publicInputs } = proofdata;

    console.log = originalConsoleLog; // restore the original console.log function after proof generation is complete

    // ABI encode the proof to be sent to the smart contract
    const encodedProof = ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes",'bytes32[]'], 
      [proof, publicInputs], 
    );


    return encodedProof;
  } catch (e) {
    console.error(e);
    throw e;
  }
}

(async () => {
  try {
    const proof = await generateProof();
    process.stdout.write(proof);
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
})();

function getHexString(input: Uint8Array<ArrayBufferLike>): string {
  const commitmentHex = "0x" + Buffer.from(input).toString("hex");

  return commitmentHex;
}
