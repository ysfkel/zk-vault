pragma solidity 0.8.34;
import {Test, console} from "forge-std/Test.sol";
import { ZKVault } from "../src/ZKVault.sol";
import {Poseidon2} from "@poseidon2/Poseidon2.sol";
import { HonkVerifier , IVerifier} from "../src/Verifier.sol";
import { IncrementalMerkleTree } from "../src/IncrementalMerkleTree.sol";

contract ZKVaultTest is Test {
    ZKVault public zkVault;
    Poseidon2 public poseidon;
    IVerifier public verifier;
    IncrementalMerkleTree public tree;
    address public recipient = address(0x1);

    function setUp() public {
        poseidon = new Poseidon2();
        verifier = new HonkVerifier();
        tree = new IncrementalMerkleTree(20, poseidon);
        zkVault = new ZKVault(20, IVerifier(verifier), poseidon); 
    }

    function testDeposit() public {
        (bytes32 commitment, bytes32 nullifier, bytes32 secret) = _getCommitment();
        console.logBytes32(commitment);
        vm.expectEmit(true, false, false, true);
        emit ZKVault.Deposit(commitment, 0, block.timestamp);
        zkVault.deposit{value:  zkVault.DENOMINATION()}(commitment);
    }

    function testWithdraw() public {
        (bytes32 commitment, bytes32 nullifier, bytes32 secret) = _getCommitment();
  
        emit ZKVault.Deposit(commitment, 0, block.timestamp);
        zkVault.deposit{value:  zkVault.DENOMINATION()}(commitment);

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = commitment;

        (bytes memory proof, bytes32[] memory publicInputs) = _getProof(nullifier, secret, recipient, leaves);
       
        assertTrue(verifier.verify(proof, publicInputs));
        bytes32 root = publicInputs[0];
        bytes32 _nullifierHash = publicInputs[1];
        address receiver = address(uint160(uint256(publicInputs[2])));

        vm.assertEq(recipient.balance, 0); 
        vm.assertEq(address(zkVault).balance, zkVault.DENOMINATION());
        zkVault.withdraw(proof, root, _nullifierHash, receiver);
        vm.assertEq(recipient.balance, zkVault.DENOMINATION());
        vm.assertEq(address(zkVault).balance, 0);
    }


    function testAnotherAddressSendProof() public {
        // make a deposit
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit ZKVault.Deposit(_commitment, 0, block.timestamp);
        zkVault.deposit{value: zkVault.DENOMINATION()}(_commitment);

        // create a proof
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);

        // make a withdrawal
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        zkVault.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(attacker));
    }

    function _getProof(bytes32 nullifier, bytes32 secret, address recipient, bytes32[] memory leaves) internal returns(bytes memory proof, bytes32[] memory publicInputs) {
        // 3 is least number of leaves required to generate a proof for a tree of depth 20
        // first 3 being inputs 0, 1, 2 which are the commands to run the script that generates the proof 
        string[] memory input = new string[](6 + leaves.length);
        input[0] = "npx";
        input[1] = "tsx";
        input[2] = "js-scripts/src/generate_proof.ts";
        input[3] = vm.toString(nullifier);
        input[4] = vm.toString(secret);
        input[5] = vm.toString(bytes32(uint256(uint160(recipient))));

        for (uint i = 0; i < leaves.length; i++) {
            input[6 + i] = vm.toString(leaves[i]);
        }

        bytes memory result = vm.ffi(input);
         (proof, publicInputs) =  abi.decode(result, (bytes, bytes32[]));
    }

    function _getCommitment()  internal returns (bytes32 commitment, bytes32 nullifier, bytes32 secret) {
        // generate_commitment.js

        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/src/generate_commitment.ts";

        bytes memory result = vm.ffi(inputs);
        // decode the result to get the commitment
       (commitment, nullifier, secret) = abi.decode(result, (bytes32, bytes32, bytes32));
    

        //return poseidon.hash([bytes32(secret), bytes32(nullifier)]);
    }
}
