// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {ZkSyncChainChecker} from "../lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleTree} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirdropTest is Test, ZkSyncChainChecker {
    BagelToken public bagelToken;
    MerkleAirdrop public merkelTree;
    bytes32 public root =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address gaspayer;
    address user;
    uint userPrivateKey;

    uint constant AMOUNT = 25 * 1e18;
    bytes32 public proof1 =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 public proof2 =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proof = [proof1, proof2];
    uint constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint constant AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;

    function setUp() public {
        if (!isZkSyncChain()) {
            //chain verification
            DeployMerkleTree deployer = new DeployMerkleTree();
            (merkelTree, bagelToken) = deployer.deployMerkleAirdrop();
        } else {
            bagelToken = new BagelToken();
            merkelTree = new MerkleAirdrop(root, bagelToken);
            bagelToken.mint(bagelToken.owner(), AMOUNT_TO_MINT);
            bagelToken.transfer(address(merkelTree), AMOUNT_TO_CLAIM);
        }
        (user, userPrivateKey) = makeAddrAndKey("user");
        gaspayer = makeAddr("gaspayer");
    }

    function testUserClaimToken() public {
        uint startingBalance = bagelToken.balanceOf(user);
        bytes32 digest = merkelTree.getmessage(user, AMOUNT_TO_CLAIM);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        vm.prank(gaspayer);
        merkelTree.claim(user, AMOUNT, proof, v, r, s);

        uint endingBalance = bagelToken.balanceOf(user);

        assertEq(endingBalance - startingBalance, AMOUNT);
    }
}
