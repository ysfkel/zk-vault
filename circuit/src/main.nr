mod merkle_tree;

use ::poseidon::poseidon2;


/// The 20 is the depth of the Merkle tree. A Merkle proof needs one sibling hash per level
/// so for a tree of depth d the proof has exactly d elements.
/// Depth ```20 -> up to 2^20 = 1,048,576 leaves (deposits/commitments)```
/// This is the same size Tornado Cash uses -- large enough that the
/// anonymity set can grow into the millions, but small enough that proving/verifying
/// stays cheap (each extra level adds one hash to the in-circuit path computation)
/// So in
/// ```circuit/src/main.nr:6, merkle_proof: [Field; 20]```  means: "the 20 sibling
/// hashes needed to walk a leaf up to the root of a 2^20-capacity tree."
/// One side note unrelated to your question: merkle_proof and secret are marked
/// pub -- for a mixer those should almost certainly be private witnesses (drop the pub),
/// otherwise you leak the path and the secret on-chain.

fn main(
    // public inputs
     root: pub Field,
     nullifier_hash: pub Field,
     recipient: pub Field, // we tie the recipient to the proof to prevent front-running attacks where someone sees a valid proof and tries to use it before the intended recipient can. By including the recipient in the public inputs, we ensure that the proof can only be used by the intended recipient.

     // private inputs
     nullifier:  Field,
     secret:  Field,
     merkle_proof:  [Field;20], // uses a merkle tree with depth 20
     is_even:  [bool; 20]  
     
) {
    // compute the commitment from the secret and nullifier
    let commitment: Field = poseidon2::Poseidon2::hash([nullifier, secret], 2);

    let  computed_nullifier_hash = poseidon2::Poseidon2::hash([nullifier], 1);

    assert(nullifier_hash == computed_nullifier_hash);

    // check that the commitment is in the merkle tree 
    let computed_root: Field = merkle_tree::compute_merkle_root(commitment, merkle_proof, is_even);

    assert(root == computed_root); 

    let address_pow = recipient * recipient;
    assert(address_pow == recipient * recipient); // This assertion is just to use the address variable and prevent it from being optimized out
   
}
 