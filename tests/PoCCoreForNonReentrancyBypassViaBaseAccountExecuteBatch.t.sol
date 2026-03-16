// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BaseTest} from "./BaseTest.t.sol";
import {AtomWallet} from "src/protocol/wallet/AtomWallet.sol";
import {BaseAccount} from "lib/account-abstraction/contracts/core/BaseAccount.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PoCCore is BaseTest {
    function test_submissionValidity() external {
        address nobody = address(0xdead);

        // 1) Alice creates an atom
        createAtomWithDeposit(bytes("alice-atom"), 1 ether, users.alice);

        // 2) Deploy the AtomWallet for alice's atom
        bytes32 atomId = calculateAtomId(bytes("alice-atom"));
        address aliceAtomWalletAddr = protocol.atomWalletFactory.deployAtomWallet(atomId);
        AtomWallet aliceAtomWallet = AtomWallet(payable(aliceAtomWalletAddr));
        vm.stopPrank();

        // 3) ATOM_WARDEN initiates 2-step ownership transfer to wallet (JUST FOR EASIER TESTING REENTRY)
        vm.prank(address(ATOM_WARDEN));
        aliceAtomWallet.transferOwnership(aliceAtomWalletAddr);

        // 4) Wallet accepts ownership
        vm.prank(aliceAtomWalletAddr);
        aliceAtomWallet.acceptOwnership();

        // 5) Fund the wallet with some ether
        uint256 walletInitialBalance = 1 ether;
        vm.deal(aliceAtomWalletAddr, walletInitialBalance);

        //6) AtomWallet.executeBatch(AtomWallet.execute())
        address[] memory dest = new address[](1);
        dest[0] = aliceAtomWalletAddr;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(AtomWallet.execute.selector, nobody, aliceAtomWalletAddr.balance, "");

        vm.prank(address(ENTRY_POINT));
        vm.expectRevert(abi.encodeWithSelector(ReentrancyGuardUpgradeable.ReentrancyGuardReentrantCall.selector));
        aliceAtomWallet.executeBatch(dest, values, data);

        // 7) BaseAccount.executeBatch(AtomWallet.execute())
        BaseAccount.Call[] memory calls = new BaseAccount.Call[](1);
        calls[0] = BaseAccount.Call({
            target: aliceAtomWalletAddr,
            value: 0,
            data: abi.encodeWithSelector(AtomWallet.execute.selector, nobody, aliceAtomWalletAddr.balance, "")
        });

        vm.prank(address(ENTRY_POINT));
        aliceAtomWallet.executeBatch(calls);

        assertTrue(nobody.balance == walletInitialBalance, "FAIL");
    }
}
