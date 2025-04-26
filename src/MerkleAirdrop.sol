// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    address[] claimers;
    bytes32 immutable i_Merkle_Root;
    IERC20 immutable i_airdropToken;
    mapping(address => bool) private s_hasClaimed;
    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirDropClaim {
        address account;
        uint amount;
    }

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();
    event Claim(address indexed _account, uint _ammount);

    constructor(
        bytes32 root,
        IERC20 airdropToken
    ) EIP712("Merkle Airdrop", "1") {
        i_Merkle_Root = root;
        i_airdropToken = airdropToken;
    }

    function claim(
        address _account,
        uint _ammount,
        bytes32[] calldata merkelProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (s_hasClaimed[_account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        if (
            !_validSignature(_account, getmessage(_account, _ammount), v, r, s)
        ) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(_account, _ammount)))
        );
        if (!MerkleProof.verify(merkelProof, i_Merkle_Root, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[_account] = true;
        emit Claim(_account, _ammount);
        i_airdropToken.safeTransfer(_account, _ammount);
    }

    function getmessage(
        address _acount,
        uint _amount
    ) public returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEHASH,
                        AirDropClaim({account: _acount, amount: _amount})
                    )
                )
            );
    }

    function _validSignature(
        address _acount,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSIgnature, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSIgnature == _acount;
    }

    function gethasClaimed(address _acount) external returns (bool) {
        return s_hasClaimed[_acount];
    }

    function getmarkelroot() external returns (bytes32) {
        return i_Merkle_Root;
    }

    function getAirdropTOken() external returns (IERC20) {
        return i_airdropToken;
    }
}
