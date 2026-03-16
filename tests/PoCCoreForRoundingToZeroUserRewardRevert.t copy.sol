// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.29;

import {BaseTest} from "./BaseTest.t.sol";
import {ITrustBonding} from "src/interfaces/ITrustBonding.sol";

contract PoCCore is BaseTest {
    function test_submissionValidity() external {
        //Epoch 4: rawUserRewards = 1 (> 0)
        _advanceEpochs(4);
        _setUserVeTRUSTBalance(users.alice, 0, 1);
        _setTotalVeTRUSTSupply(3, protocol.trustBonding.emissionsForEpoch(3));
        assertTrue(
            protocol.trustBonding.userEligibleRewardsForEpoch(users.alice, 3) > 0,
            "alice should have rewards to claim"
        );

        //But user can't claimReward() because userRewards = rawUserRewards * utilizationRatio = 0
        resetPrank(users.alice);
        vm.expectRevert(abi.encodeWithSelector(ITrustBonding.TrustBonding_NoRewardsToClaim.selector));
        protocol.trustBonding.claimRewards(users.alice);

        //Next epoch, user's treated as they didn't claim reward for previous epoch, so their reward is penalized by utilization ratio (only personalUtilizationLowerBound)
        _advanceEpochs(5);
        _setActiveEpoch(users.alice, 0, 4);
        _setUserUtilizationForEpoch(users.alice, 4, 100000);
        _setUserVeTRUSTBalance(users.alice, 4, 100000);
        assertTrue(
            protocol.trustBonding.getPersonalUtilizationRatio(users.alice, 4) ==
                protocol.trustBonding.personalUtilizationLowerBound(),
            "personal utilization ratio should be at the lower bound"
        );
    }

    function _advanceEpochs(uint256 epochs) internal {
        uint256 currentEpoch = protocol.trustBonding.currentEpoch();
        uint256 currentEpochEndTimestamp = protocol.trustBonding.epochTimestampEnd(currentEpoch);
        uint256 targetTimestamp = currentEpochEndTimestamp + epochs * protocol.trustBonding.epochLength();
        vm.warp(targetTimestamp - 1);
    }

    function _setUserUtilizationForEpoch(address user, uint256 epoch, int256 utilization) internal {
        // The MultiVault contract stores personalUtilization in a nested mapping
        // mapping(address user => mapping(uint256 epoch => int256 utilization)) public personalUtilization;

        // Calculate the storage slot for the nested mapping
        bytes32 userSlot = keccak256(abi.encode(user, uint256(31))); // MultiVault personalUtilization storage slot
        bytes32 finalSlot = keccak256(abi.encode(epoch, userSlot));
        vm.store(address(protocol.multiVault), finalSlot, bytes32(uint256(utilization)));
    }

    function _setActiveEpoch(address user, uint256 index, uint256 epoch) internal {
        require(index < 3, "index out of bounds");
        uint256 mappingSlot = 32; // storage slot for userEpochHistory mapping in MultiVault
        bytes32 baseSlot = keccak256(abi.encode(user, uint256(mappingSlot)));
        bytes32 targetSlot = bytes32(uint256(baseSlot) + index);
        vm.store(address(protocol.multiVault), targetSlot, bytes32(epoch));
    }

    function _setUserVeTRUSTBalance(address user, uint256 _epoch, uint256 desiredBalance) internal {
        uint256 targetTs = protocol.trustBonding.epochTimestampEnd(_epoch);
        uint256 currentUserEpoch = protocol.trustBonding.user_point_epoch(user);
        uint256 newUserEpoch = currentUserEpoch + 1;

        uint256 USER_POINT_HISTORY_MAPPING_SLOT = 7;
        uint256 USER_POINT_EPOCH_MAPPING_SLOT = 8;

        // Base of user_point_history[user]
        bytes32 arrayBase = keccak256(abi.encode(user, USER_POINT_HISTORY_MAPPING_SLOT));

        // Start slot of user_point_history[user][newUserEpoch]
        // Each Point occupies 3 consecutive slots.
        bytes32 pointSlot = bytes32(uint256(arrayBase) + newUserEpoch * 3);
        bytes32 biasAndSlope = bytes32(uint256(uint128(desiredBalance)));

        vm.store(
            address(protocol.trustBonding),
            pointSlot, // bias | slope
            biasAndSlope
        );
        vm.store(
            address(protocol.trustBonding),
            bytes32(uint256(pointSlot) + 1), // ts
            bytes32(targetTs)
        );
        vm.store(
            address(protocol.trustBonding),
            bytes32(uint256(pointSlot) + 2), // blk
            bytes32(block.number)
        );

        bytes32 userEpochSlot = keccak256(abi.encode(user, USER_POINT_EPOCH_MAPPING_SLOT));
        vm.store(address(protocol.trustBonding), userEpochSlot, bytes32(newUserEpoch));
    }

    function _setTotalVeTRUSTSupply(uint256 _epoch, uint256 desiredTotalSupply) internal {
        uint256 targetTs = protocol.trustBonding.epochTimestampEnd(_epoch);

        // Append after the current last global checkpoint
        uint256 currentGlobalEpoch = protocol.trustBonding.epoch();
        uint256 newGlobalEpoch = currentGlobalEpoch + 1;

        uint256 POINT_HISTORY_MAPPING_SLOT = 6;
        uint256 EPOCH_SLOT = 5;

        bytes32 pointSlot = keccak256(abi.encode(newGlobalEpoch, POINT_HISTORY_MAPPING_SLOT));
        bytes32 biasAndSlope = bytes32(uint256(uint128(desiredTotalSupply)));

        vm.store(address(protocol.trustBonding), pointSlot, biasAndSlope);
        vm.store(address(protocol.trustBonding), bytes32(uint256(pointSlot) + 1), bytes32(targetTs));
        vm.store(address(protocol.trustBonding), bytes32(uint256(pointSlot) + 2), bytes32(block.number));

        vm.store(address(protocol.trustBonding), bytes32(EPOCH_SLOT), bytes32(newGlobalEpoch));
    }
}
