// SDPX - License-Identifier: MIT
pragma solidity 0.8.34;
import "./IncrementalMerkleTree.sol";
import { IVerifier } from "./Verifier.sol";

/// @title ZK Vault
/// @notice Do not deploy on mainnet or use with real funds. This contract is not auditted and intended for demonstration of zero-knowledge proof verification in a simple mixer-like application.
/// @dev Implements private withdrawals using zero-knowledge proofs and nullifiers.
/// @dev Inherits from `IncrementalMerkleTree`. Deposits add commitments to the Merkle tree; withdrawals verify
///      a ZK proof that a commitment exists and mark the corresponding nullifier hash as spent to prevent double-spend.
contract ZKVault is IncrementalMerkleTree {
    IVerifier public immutable verifier;
    uint256 public constant DENOMINATION = 0.001 ether;
    mapping(bytes32 _commitment => bool) public commitments;
    mapping(bytes32 _nullifierHash => bool) public _nullifierHashes;

    error ZKVault__ZerorAddress();
    error ZKVault__InvalidCommitment();
    error ZKVault__InvalidDepositAmount(uint256 amountSent, uint256 expectedAmount);
    error ZKVault__UnknownRoot(bytes32 root);
    error ZKVault__NullifierAlreadyUsed(bytes32 _nullifierHash);
    error ZKVault__TransferFailed(address reciever, uint256 amount);
    error ZKVault__InvalidProof();

    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdraw(bytes32 indexed nullifierHash, address indexed receiver, uint256 timestamp);

    /// @dev Construct the ZK Vault.
    /// @param _depth Tree depth passed to the inherited `IncrementalMerkleTree`.
    /// @param _verifier Address of the on-chain verifier contract used to verify ZK proofs.
    /// @param _hasher Poseidon2 hasher instance used by the incremental Merkle tree.
    constructor(uint32 _depth,IVerifier _verifier,  Poseidon2 _hasher) IncrementalMerkleTree(_depth, _hasher) {
        require(address(_verifier) != address(0), ZKVault__ZerorAddress());
        verifier = _verifier;
    }

    /// @dev Deposit a fixed denomination amount and add a commitment to the tree.
    /// @param _commitment Poseidon commitment computed off-chain as `Poseidon2(nullifier, secret)`.
    /// @dev Emits a {Deposit} event with the inserted leaf index.
    function deposit(bytes32 _commitment) external payable {
        require(msg.value == DENOMINATION, ZKVault__InvalidDepositAmount(msg.value, DENOMINATION));
        require(!commitments[_commitment], ZKVault__InvalidCommitment());

        commitments[_commitment] = true;
        uint32 _insertedIndex = _insert(_commitment); // returns leaf index where the commitment was inserted in the tree

        emit Deposit(_commitment, _insertedIndex, block.timestamp);
    }

        /// @dev Withdraw funds by presenting a ZK proof that a known commitment exists and the nullifier is unused.
        /// @param proof ABI-encoded proof bytes produced by the prover.
        /// @param root Merkle tree root used as a public input to the proof.
        /// @param _nullifierHash Public Poseidon hash of the nullifier (used to prevent double-spend).
        /// @param receiver Address that will receive the denomination on success.
        /// @dev Verifies the proof via `verifier.verify(proof, publicInputs)`, marks `_nullifierHash` spent, and transfers funds.
        function withdraw(bytes memory proof, bytes32 root, bytes32 _nullifierHash, address receiver) external {
        // check that the root that was used in the proof matches the current root of the tree
        require(isKnownRoot(root), ZKVault__UnknownRoot(root));
        // check that the nullifier has not yet been used to prevent double spending
        require(!_nullifierHashes[_nullifierHash],ZKVault__NullifierAlreadyUsed(_nullifierHash));  
        // check that the proof is valid by calling the verifier contract
        _nullifierHashes[_nullifierHash] = true;
        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = root;
        publicInputs[1] = _nullifierHash;
        publicInputs[2] = bytes32(uint256(uint160(receiver)));

        require(verifier.verify(proof, publicInputs), ZKVault__InvalidProof());
        // send the funds
        (bool success,) = receiver.call{value: DENOMINATION}("");
        require(success, ZKVault__TransferFailed(receiver, DENOMINATION));
        
        emit Withdraw(_nullifierHash, receiver, block.timestamp);
    }
}
