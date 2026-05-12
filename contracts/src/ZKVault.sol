// SDPX - License-Identifier: MIT
pragma solidity 0.8.34;
import "./IncrementalMerkleTree.sol";
import { IVerifier } from "./Verifier.sol";

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

    constructor(uint32 _depth,IVerifier _verifier,  Poseidon2 _hasher) IncrementalMerkleTree(_depth, _hasher) {
        require(address(_verifier) != address(0), ZKVault__ZerorAddress());
        verifier = _verifier;
    }

    // @notice Deposit funds into the mixer
    // @param The poseidon commitment of the secret and nullifier
    function deposit(bytes32 _commitment) external payable {
        require(msg.value == DENOMINATION, ZKVault__InvalidDepositAmount(msg.value, DENOMINATION));
        require(!commitments[_commitment], ZKVault__InvalidCommitment());

        commitments[_commitment] = true;
        uint32 _insertedIndex = _insert(_commitment); // returns leaf index where the commitment was inserted in the tree

        emit Deposit(_commitment, _insertedIndex, block.timestamp);
    }

     /// @notice Withdraw funds from the mixer in a way that preserves privacy
     /// @param proof The zk-SNARK proof that the user is entitled to withdraw funds
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
