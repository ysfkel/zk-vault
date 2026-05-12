
use ::poseidon::poseidon2;

pub fn compute_merkle_root(
    leaf: Field,
    merkle_proof: [Field; 20],
    is_even: [bool; 20]
) -> Field {

    // temporary variable to hold the current hash as we walk up the tree
    let mut hash: Field = leaf;

    // walk up the tree
    for i in 0..20 { 
        let (left, right) = if is_even[i] {
            (hash, merkle_proof[i])
        } else {
            (merkle_proof[i], hash)
         };
        hash  = poseidon2::Poseidon2::hash([left, right], 2); 
    }

    hash
} 