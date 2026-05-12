// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Poseidon2} from "@poseidon2/Poseidon2.sol";
import {Field} from "@poseidon2/Field.sol";

/// @title Incremental Merkle Tree
/// @notice For educational purposes only. Simple incremental Merkle tree using Poseidon hashing and a fixed depth.
/// @dev Stores recent roots in a ring buffer (`roots`) and supports incremental leaf insertion via `_insert`.
contract IncrementalMerkleTree {
    // BN256 scalar field

    uint256 constant PRIME = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001; // obtained from https://github.com/zemse/poseidon2-evm/blob/main/src/bn254/solidity/Field.sol

    // obtaining default value used to set leaves
    // to hash we will use keccak256.
    // problem is hash is passed to a posseidon2 hash function
    // which has input  field size less than the max size of keccak256
    // this means we need to use tha max size of the posseidon2 hash function and do modulus to make sure the result is less than the fiekd size
    // DEFAULT_NODE_HASH = bytes32(uint256(keccak256(<"some string">)) % PRIME); // PRIME is a constant defined above - note this is done offchain and then passed to constructor
    uint256 immutable DEFAULT_NODE_HASH;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    uint32 public currentRootIndex = 0;
    uint32 public immutable depth; // leaves = 2^depth
    uint32 public nextLeafIndex = 0; // the index of the next leaf index to be inserted into the tree
    Poseidon2 public immutable hasher;

    mapping(uint256 => bytes32) public cachedSubtrees; // subtrees for already stored commitments
    mapping(uint256 => bytes32) public roots;

    error IncrementalMerkleTree__TreeDepthCannotBeZero(uint256 depth);
    error IncrementalMerkleTree__TreeDepthLessThan32Expected(uint256 depth);
    error IncrementalMerkleTree__MerkleTreeIsFull(uint256 nextLeafIndex);

    /// @dev Initialize tree parameters and set the empty root.
    /// @param _depth Number of levels in the tree (depth > 0 and < 32).
    /// @param _hasher Poseidon2 hasher contract used for internal node hashing.
    constructor(uint32 _depth, Poseidon2 _hasher) {
        require(_depth > 0, IncrementalMerkleTree__TreeDepthCannotBeZero(_depth));
        require(_depth < 32, IncrementalMerkleTree__TreeDepthLessThan32Expected(_depth));
        depth = _depth;
        hasher = _hasher;
        roots[0] = zeros(_depth); // set thse root of the empty tree to be the hash of the default node at the maximum depth - this is because when the tree is empty, all the nodes are default nodes, so the root is the hash of the default node at the maximum depth
    }

    /// @dev Insert a new leaf into the incremental Merkle tree.
    /// @param leaf The leaf value (bytes32) to insert (typically a commitment).
    /// @return _nextLeafIndex The index where the leaf was inserted.
    /// @dev Updates cached subtrees and stores the new root into the `roots` ring buffer. Reverts if the tree is full.
    function _insert(bytes32 leaf) internal virtual returns (uint32 _nextLeafIndex) {
        // check if the tree is full by checking if the next leaf index is less
        //  than the maximum number of leaves in the tree which is 2^depth
        require(nextLeafIndex < uint32(2) ** depth, IncrementalMerkleTree__MerkleTreeIsFull(nextLeafIndex));
        _nextLeafIndex = nextLeafIndex;

        // figure if the index is even or odd
        // if even, we place it on the left and the right node is the default node. store the hash of the leaf and the default node in a mapping to avoid recomputing the hash of the default node multiple times
        // if odd, we place it on the right and the left node is the default node. store the hash of the leaf and the default node in a mapping to avoid recomputing the hash of the default node multiple times
        // we do this iteratively until we reach the root and update the root at the end
        uint256 currentIndex = _nextLeafIndex;
        bytes32 currentHash = leaf;
        bytes32 left;
        bytes32 right;
        // It iterates depth times — climbing from the leaf all the way to the apex.
        // After the loop, currentHash is the root of the whole tree, and that's what gets stored in roots[newRootIndex].
        for (uint32 i = 0; i < depth; i++) {
            if (currentIndex % 2 == 0) {
                // even index, place on the left
                left = currentHash;
                right = zeros(i); // get the hash of the default node at depth i
                cachedSubtrees[i] = currentHash;
            } else {
                // odd index, place on the right
                left = cachedSubtrees[i];
                right = currentHash;
            }

            currentHash = Field.toBytes32(hasher.hash_2(Field.toField(left), Field.toField(right)));
            currentIndex = currentIndex / 2; // move to the parent index
        }

        // at this point we have calculated the root of the tree, so we can store it in the roots array
        // calculate the next index in the array
        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        // store the index of the new root we are adding
        currentRootIndex = newRootIndex;
        // store the new root in the roots array
        roots[newRootIndex] = currentHash;
        // store the index of the next leaf to be inserted ready for the next deposit
        nextLeafIndex = _nextLeafIndex + 1;
        // return the index of the leaf we just inserted to be passed to the deposit event
        return _nextLeafIndex;
    }

    /// @dev Check whether a root is present in recent root history.
    /// @param _root The Merkle root to check for membership in the root history.
    /// @return bool True if the root exists in the ring buffer, false otherwise.
    function isKnownRoot(bytes32 _root) public view returns(bool) {
        if (_root == bytes32(0)) {
            return false;
        }

        uint32 _currentRootIndex = currentRootIndex; // cache the current root index to avoid reading from storage multiple times
        uint32 i = _currentRootIndex;
       do {

            if (roots[i] == _root) {
                return true;
            }
            // move to the previous root index, wrap around if necessary
            if (i == 0) {
                i = ROOT_HISTORY_SIZE - 1;
            } else {
                i--;
            }

       } while (i != _currentRootIndex);

       return false;

    }


    /// @dev Return the default (zero) node hash for a given level `i`.
    /// @param i The tree level (0 = leaf level) for which to return the precomputed zero hash.
    /// @return bytes32 The precomputed zero/default node hash used for empty branches.
    /// @dev These values can be computed off-chain and hardcoded to avoid repeated recomputation.
    function zeros(uint256 i) public pure returns (bytes32) {
        // in poseidon , Field.Type is a byte type whose value is smaller than uint245
        //
        // to hash we will use keccak256.
        // problem is hash is passed to a posseidon2 hash function
        // which has input  field size less than the max size of keccak256
        // this means we need to use tha max size of the posseidon2 hash function and do modulus to make sure the result is less than the fiekd size
        // DEFAULT_NODE_HASH = bytes32(uint256(keccak256(<"some string">)) % PRIME); // PRIME is a constant defined above

        if (i == 0) {
            // return the computed leaf node which is the hash of 0 - see test test_hash_depth_0_leaf in Mixer.t.sol for the result of this hash
            return bytes32(0x0d823319708ab99ec915efd4f7e03d11ca1790918e8f04cd14100aceca2aa9ff);
        } else if (i == 1) {
            // return the computed hash of the leaf node - see test test_hash_depth_1 in Mixer.t.sol for the result of this hash
            return bytes32(0x170a9598425eb05eb8dc06986c6afc717811e874326a79576c02d338bdf14f13);
        } else if (i == 2) {
            // return the computed hash of the hash of the leaf node - see test test_hash_depth_2 in Mixer.t.sol for the result of this hash
            return bytes32(0x273b1a40397b618dac2fc66ceb71399a3e1a60341e546e053cbfa5995e824caf);
        } else if (i == 3) {
            // return the computed hash of the hash of the hash of the leaf node - see test test_hash_depth_3 in Mixer.t.sol for the result of this hash
            return bytes32(0x16bf9b1fb2dfa9d88cfb1752d6937a1594d257c2053dff3cb971016bfcffe2a1);
        } else if (i == 4) {
            // return the computed hash of the hash of the hash of the hash of the leaf node - see test test_hash_depth_4 in Mixer.t.sol for the result of this hash
            return bytes32(0x1288271e1f93a29fa6e748b7468a77a9b8fc3db6b216ce5fc2601fc3e9bd6b36);
        } else if (i == 5) {
            // return the computed hash of the hash of the hash of the hash of the hash of the leaf node - see test test_hash_depth_5 in Mixer.t.sol for the result of this hash
            return bytes32(0x1d47548adec1068354d163be4ffa348ca89f079b039c9191378584abd79edeca);
        } else if (i == 6) {
            // return the computed hash of the hash of the hash of the hash of the hash of the hash of the leaf node - see test test_hash_depth_6 in Mixer.t.sol for the result of this hash
            return bytes32(0x0b98a89e6827ef697b8fb2e280a2342d61db1eb5efc229f5f4a77fb333b80bef);
        } else if (i == 7) {
            // return the computed hash of the hash of the hash of the hash of the hash of the hash of the hash of the leaf node - see test test_hash_depth_7 in Mixer.t.sol for the result of this hash
            return bytes32(0x231555e37e6b206f43fdcd4d660c47442d76aab1ef552aef6db45f3f9cf2e955);
        } else if (i == 8) {
            return bytes32(0x03d0dc8c92e2844abcc5fdefe8cb67d93034de0862943990b09c6b8e3fa27a86);  
        } else if (i == 9) {
            return bytes32(0x1d51ac275f47f10e592b8e690fd3b28a76106893ac3e60cd7b2a3a443f4e8355); 
        } else if (i == 10) {
            return bytes32(0x16b671eb844a8e4e463e820e26560357edee4ecfdbf5d7b0a28799911505088d);  
        } else if (i == 11) {
            return bytes32(0x115ea0c2f132c5914d5bb737af6eed04115a3896f0d65e12e761ca560083da15);  
        } else if (i == 12) {
            return bytes32(0x139a5b42099806c76efb52da0ec1dde06a836bf6f87ef7ab4bac7d00637e28f0); 
        } else if (i == 13) {
            return bytes32(0x0804853482335a6533eb6a4ddfc215a08026db413d247a7695e807e38debea8e); 
        } else if (i == 14) {
            return bytes32(0x2f0b264ab5f5630b591af93d93ec2dfed28eef017b251e40905cdf7983689803);  
        } else if (i == 15) {
            return bytes32(0x170fc161bf1b9610bf196c173bdae82c4adfd93888dc317f5010822a3ba9ebee);  
        } else if (i == 16) {
            return bytes32(0x0b2e7665b17622cc0243b6fa35110aa7dd0ee3cc9409650172aa786ca5971439); 
        } else if (i == 17) {
            return bytes32(0x12d5a033cbeff854c5ba0c5628ac4628104be6ab370699a1b2b4209e518b0ac5);  
        } else if (i == 18) {
            return bytes32(0x1bc59846eb7eafafc85ba9a99a89562763735322e4255b7c1788a8fe8b90bf5d);  
        } else if (i == 19) {
            return bytes32(0x1b9421fbd79f6972a348a3dd4721781ec25a5d8d27342942ae00aba80a3904d4);  
        } else if (i == 20) {
            return bytes32(0x087fde1c4c9c27c347f347083139eee8759179d255ec8381c02298d3d6ccd233); 
        } else if (i == 21) {
            return bytes32(0x1e26b1884cb500b5e6bbfdeedbdca34b961caf3fa9839ea794bfc7f87d10b3f1);  
        } else if (i == 22) {
            return bytes32(0x09fc1a538b88bda55a53253c62c153e67e8289729afd9b8bfd3f46f5eecd5a72);  
        } else if (i == 23) {
            return bytes32(0x14cd0edec3423652211db5210475a230ca4771cd1e45315bcd6ea640f14077e2);  
        } else if (i == 24) {
            return bytes32(0x1d776a76bc76f4305ef0b0b27a58a9565864fe1b9f2a198e8247b3e599e036ca); 
        } else if (i == 25) {
            return bytes32(0x1f93e3103fed2d3bd056c3ac49b4a0728578be33595959788fa25514cdb5d42f);  
        } else if (i == 26) {
            return bytes32(0x138b0576ee7346fb3f6cfb632f92ae206395824b9333a183c15470404c977a3b);  
        } else if (i == 27) {
            return bytes32(0x0745de8522abfcd24bd50875865592f73a190070b4cb3d8976e3dbff8fdb7f3d);  
        } else if (i == 28) {
            return bytes32(0x2ffb8c798b9dd2645e9187858cb92a86c86dcd1138f5d610c33df2696f5f6860);  
        } else if (i == 29) {
            return bytes32(0x2612a1395168260c9999287df0e3c3f1b0d8e008e90cd15941e4c2df08a68a5a); 
        } else if (i == 30) {
            return bytes32(0x10ebedce66a910039c8edb2cd832d6a9857648ccff5e99b5d08009b44b088edf);  
        } else if (i == 31) {
            return bytes32(0x213fb841f9de06958cf4403477bdbff7c59d6249daabfee147f853db7c808082);  
        } else {
            revert("Depth not supported");
        }
    }
}
