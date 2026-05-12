pragma solidity 0.8.34;
import {Test} from "forge-std/Test.sol";
import {IncrementalMerkleTree} from "../src/IncrementalMerkleTree.sol";
import {Poseidon2} from "@poseidon2/Poseidon2.sol";
import {Field} from "@poseidon2/Field.sol";

contract IncrementalMerkleTreeTest is Test {
    IncrementalMerkleTree public tree;
    Poseidon2 public poseidon;
    uint32 public constant DEPTH = 31;

    function setUp() public {
        poseidon = new Poseidon2();
        // uint256 defaultNodeHash = uint256(poseidon.hash_1(0));
        tree = new IncrementalMerkleTree(DEPTH, poseidon);
    }

    function test_initialization() public view {
        vm.assertEq(tree.depth(), DEPTH);
        bytes32 currentRoot = tree.roots(0);
        bytes32 zeroRoot = tree.zeros(DEPTH);
        vm.assertEq(currentRoot, zeroRoot);
    }

    // Compute the empty root by hashing up from scratch using only zeros(0) (the leaf value) and the live hasher, then compare to roots(0):
    function test_seedRootMatchesComputedEmptyRoot() public view {
        bytes32 h = tree.zeros(0); // start at leaf level
        // Manually compute what _insert would produce if you inserted zeros(0) at index 0
        for (uint32 i = 0; i < DEPTH; i++) {
            h = Field.toBytes32(poseidon.hash_2(Field.toField(h), Field.toField(tree.zeros(i))));
        }
        // If this passes for depths 1, 4, 20, and 31, the constructor seed is bulletproof.
        vm.assertEq(tree.roots(0), h);
    }

    function test_hash_depth_0_leaf() public view {
        uint256 PRIMT_TO_NUMBER = uint256(Field.PRIME); // convert MAX Field value aka PRIME to integer RESULT -> 21888242871839275222246405745257275088548364400416034343698204186575808495617
        vm.assertEq(PRIMT_TO_NUMBER, 21888242871839275222246405745257275088548364400416034343698204186575808495617);
        bytes32 leaf = bytes32(uint256(keccak256("cyfrin")) % PRIMT_TO_NUMBER);
        bytes32 expectedHash = 0x0d823319708ab99ec915efd4f7e03d11ca1790918e8f04cd14100aceca2aa9ff;
        vm.assertEq(leaf, expectedHash);
        bytes32 node = tree.zeros(0);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_1() public view {
        Field.Type hash = Field.toField(uint256(0x0d823319708ab99ec915efd4f7e03d11ca1790918e8f04cd14100aceca2aa9ff));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x170a9598425eb05eb8dc06986c6afc717811e874326a79576c02d338bdf14f13;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(1);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_2() public view {
        Field.Type hash = Field.toField(uint256(0x170a9598425eb05eb8dc06986c6afc717811e874326a79576c02d338bdf14f13));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x273b1a40397b618dac2fc66ceb71399a3e1a60341e546e053cbfa5995e824caf;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(2);
        vm.assertEq(node, expectedHash);
    }

    //4:45
    function test_hash_depth_3() public view {
        Field.Type hash = Field.toField(uint256(0x273b1a40397b618dac2fc66ceb71399a3e1a60341e546e053cbfa5995e824caf));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x16bf9b1fb2dfa9d88cfb1752d6937a1594d257c2053dff3cb971016bfcffe2a1;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(3);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_4() public view {
        Field.Type hash = Field.toField(uint256(0x16bf9b1fb2dfa9d88cfb1752d6937a1594d257c2053dff3cb971016bfcffe2a1));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1288271e1f93a29fa6e748b7468a77a9b8fc3db6b216ce5fc2601fc3e9bd6b36;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(4);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_5() public view {
        Field.Type hash = Field.toField(uint256(0x1288271e1f93a29fa6e748b7468a77a9b8fc3db6b216ce5fc2601fc3e9bd6b36));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1d47548adec1068354d163be4ffa348ca89f079b039c9191378584abd79edeca;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(5);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_6() public view {
        Field.Type hash = Field.toField(uint256(0x1d47548adec1068354d163be4ffa348ca89f079b039c9191378584abd79edeca));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x0b98a89e6827ef697b8fb2e280a2342d61db1eb5efc229f5f4a77fb333b80bef;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(6);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_7() public view {
        Field.Type hash = Field.toField(uint256(0x0b98a89e6827ef697b8fb2e280a2342d61db1eb5efc229f5f4a77fb333b80bef));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x231555e37e6b206f43fdcd4d660c47442d76aab1ef552aef6db45f3f9cf2e955;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(7);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_8() public view {
        Field.Type hash = Field.toField(uint256(0x231555e37e6b206f43fdcd4d660c47442d76aab1ef552aef6db45f3f9cf2e955));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x03d0dc8c92e2844abcc5fdefe8cb67d93034de0862943990b09c6b8e3fa27a86;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(8);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_9() public view {
        Field.Type hash = Field.toField(uint256(0x03d0dc8c92e2844abcc5fdefe8cb67d93034de0862943990b09c6b8e3fa27a86));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1d51ac275f47f10e592b8e690fd3b28a76106893ac3e60cd7b2a3a443f4e8355;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(9);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_10() public view {
        Field.Type hash = Field.toField(uint256(0x1d51ac275f47f10e592b8e690fd3b28a76106893ac3e60cd7b2a3a443f4e8355));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));

        bytes32 expectedHash = 0x16b671eb844a8e4e463e820e26560357edee4ecfdbf5d7b0a28799911505088d;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(10);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_11() public view {
        Field.Type hash = Field.toField(uint256(0x16b671eb844a8e4e463e820e26560357edee4ecfdbf5d7b0a28799911505088d));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x115ea0c2f132c5914d5bb737af6eed04115a3896f0d65e12e761ca560083da15;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(11);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_12() public view {
        Field.Type hash = Field.toField(uint256(0x115ea0c2f132c5914d5bb737af6eed04115a3896f0d65e12e761ca560083da15));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x139a5b42099806c76efb52da0ec1dde06a836bf6f87ef7ab4bac7d00637e28f0;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(12);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_13() public view {
        Field.Type hash = Field.toField(uint256(0x139a5b42099806c76efb52da0ec1dde06a836bf6f87ef7ab4bac7d00637e28f0));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x0804853482335a6533eb6a4ddfc215a08026db413d247a7695e807e38debea8e;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(13);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_14() public view {
        Field.Type hash = Field.toField(uint256(0x0804853482335a6533eb6a4ddfc215a08026db413d247a7695e807e38debea8e));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x2f0b264ab5f5630b591af93d93ec2dfed28eef017b251e40905cdf7983689803;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(14);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_15() public view {
        Field.Type hash = Field.toField(uint256(0x2f0b264ab5f5630b591af93d93ec2dfed28eef017b251e40905cdf7983689803));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x170fc161bf1b9610bf196c173bdae82c4adfd93888dc317f5010822a3ba9ebee;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(15);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_16() public view {
        Field.Type hash = Field.toField(uint256(0x170fc161bf1b9610bf196c173bdae82c4adfd93888dc317f5010822a3ba9ebee));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x0b2e7665b17622cc0243b6fa35110aa7dd0ee3cc9409650172aa786ca5971439;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(16);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_17() public view {
        Field.Type hash = Field.toField(uint256(0x0b2e7665b17622cc0243b6fa35110aa7dd0ee3cc9409650172aa786ca5971439));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x12d5a033cbeff854c5ba0c5628ac4628104be6ab370699a1b2b4209e518b0ac5;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(17);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_18() public view {
        Field.Type hash = Field.toField(uint256(0x12d5a033cbeff854c5ba0c5628ac4628104be6ab370699a1b2b4209e518b0ac5));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1bc59846eb7eafafc85ba9a99a89562763735322e4255b7c1788a8fe8b90bf5d;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(18);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_19() public view {
        Field.Type hash = Field.toField(uint256(0x1bc59846eb7eafafc85ba9a99a89562763735322e4255b7c1788a8fe8b90bf5d));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1b9421fbd79f6972a348a3dd4721781ec25a5d8d27342942ae00aba80a3904d4;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(19);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_20() public view {
        Field.Type hash = Field.toField(uint256(0x1b9421fbd79f6972a348a3dd4721781ec25a5d8d27342942ae00aba80a3904d4));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x087fde1c4c9c27c347f347083139eee8759179d255ec8381c02298d3d6ccd233;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(20);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_21() public view {
        Field.Type hash = Field.toField(uint256(0x087fde1c4c9c27c347f347083139eee8759179d255ec8381c02298d3d6ccd233));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1e26b1884cb500b5e6bbfdeedbdca34b961caf3fa9839ea794bfc7f87d10b3f1;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(21);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_22() public view {
        Field.Type hash = Field.toField(uint256(0x1e26b1884cb500b5e6bbfdeedbdca34b961caf3fa9839ea794bfc7f87d10b3f1));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x09fc1a538b88bda55a53253c62c153e67e8289729afd9b8bfd3f46f5eecd5a72;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(22);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_23() public view {
        Field.Type hash = Field.toField(uint256(0x09fc1a538b88bda55a53253c62c153e67e8289729afd9b8bfd3f46f5eecd5a72));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x14cd0edec3423652211db5210475a230ca4771cd1e45315bcd6ea640f14077e2;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(23);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_24() public view {
        Field.Type hash = Field.toField(uint256(0x14cd0edec3423652211db5210475a230ca4771cd1e45315bcd6ea640f14077e2));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1d776a76bc76f4305ef0b0b27a58a9565864fe1b9f2a198e8247b3e599e036ca;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(24);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_25() public view {
        Field.Type hash = Field.toField(uint256(0x1d776a76bc76f4305ef0b0b27a58a9565864fe1b9f2a198e8247b3e599e036ca));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x1f93e3103fed2d3bd056c3ac49b4a0728578be33595959788fa25514cdb5d42f;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(25);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_26() public view {
        Field.Type hash = Field.toField(uint256(0x1f93e3103fed2d3bd056c3ac49b4a0728578be33595959788fa25514cdb5d42f));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x138b0576ee7346fb3f6cfb632f92ae206395824b9333a183c15470404c977a3b;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(26);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_27() public view {
        Field.Type hash = Field.toField(uint256(0x138b0576ee7346fb3f6cfb632f92ae206395824b9333a183c15470404c977a3b));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x0745de8522abfcd24bd50875865592f73a190070b4cb3d8976e3dbff8fdb7f3d;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(27);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_28() public view {
        Field.Type hash = Field.toField(uint256(0x0745de8522abfcd24bd50875865592f73a190070b4cb3d8976e3dbff8fdb7f3d));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x2ffb8c798b9dd2645e9187858cb92a86c86dcd1138f5d610c33df2696f5f6860;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(28);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_29() public view {
        Field.Type hash = Field.toField(uint256(0x2ffb8c798b9dd2645e9187858cb92a86c86dcd1138f5d610c33df2696f5f6860));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x2612a1395168260c9999287df0e3c3f1b0d8e008e90cd15941e4c2df08a68a5a;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(29);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_30() public view {
        Field.Type hash = Field.toField(uint256(0x2612a1395168260c9999287df0e3c3f1b0d8e008e90cd15941e4c2df08a68a5a));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x10ebedce66a910039c8edb2cd832d6a9857648ccff5e99b5d08009b44b088edf;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(30);
        vm.assertEq(node, expectedHash);
    }

    function test_hash_depth_31() public view {
        Field.Type hash = Field.toField(uint256(0x10ebedce66a910039c8edb2cd832d6a9857648ccff5e99b5d08009b44b088edf));
        Field.Type h = poseidon.hash_2(hash, hash);
        bytes32 h_bytes32 = bytes32(Field.toUint256(h));
        bytes32 expectedHash = 0x213fb841f9de06958cf4403477bdbff7c59d6249daabfee147f853db7c808082;
        vm.assertEq(h_bytes32, expectedHash);
        bytes32 node = tree.zeros(31);
        vm.assertEq(node, expectedHash);
    }
}
