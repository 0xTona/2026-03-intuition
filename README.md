# Intuition audit details
- Total Prize Pool: $17,500 in USDC
    - HM awards: up to $14,400 in USDC
        - If no valid Highs or Mediums are found, the HM pool is $0
    - QA awards: $600 in USDC
    - Judge awards: $2,000 in USDC
    - Scout awards: $500 USDC
- [Read our guidelines for more details](https://docs.code4rena.com/competitions)
- Starts March 4, 2026 20:00 UTC
- Ends March 9, 2026 20:00 UTC

### ❗ Important notes for wardens
1. Since this audit includes live/deployed code, **all submissions will be treated as sensitive**:
    - Wardens are encouraged to submit High-risk submissions affecting live code promptly, to ensure timely disclosure of such vulnerabilities to the sponsor and guarantee payout in the case where a sponsor patches a live critical during the audit.
    - Submissions will be hidden from all wardens (SR and non-SR alike) by default, to ensure that no sensitive issues are erroneously shared.
    - If the submissions include findings affecting live code, there will be no post-judging QA phase. This ensures that awards can be distributed in a timely fashion, without compromising the security of the project. (Senior members of C4 staff will review the judges’ decisions per usual.)
    - By default, submissions will not be made public until the report is published.
    - Exception: if the sponsor indicates that no submissions affect live code, then we’ll make submissions visible to all authenticated wardens, and open PJQA to SR wardens per the usual C4 process.
    - [The "live criticals" exception](https://docs.code4rena.com/awarding#the-live-criticals-exception) therefore applies.
2. A coded, runnable PoC is required for all High/Medium submissions to this audit. 
    - This repo includes a basic template to run the test suite.
    - PoCs must use the test suite provided in this repo.
    - Your submission will be marked as Insufficient if the POC is not runnable and working with the provided test suite.
    - Exception: PoC is optional (though recommended) for wardens with signal ≥ 0.4.
3. Judging phase risk adjustments (upgrades/downgrades):
    - High- or Medium-risk submissions downgraded by the judge to Low-risk (QA) will be ineligible for awards.
    - Upgrading a Low-risk finding from a QA report to a Medium- or High-risk finding is not supported.
    - As such, wardens are encouraged to select the appropriate risk level carefully during the submission phase.

## V12 findings

[V12](https://v12.zellic.io/) is [Zellic](https://zellic.io)'s in-house AI auditing tool. It is the only autonomous Solidity auditor that [reliably finds Highs and Criticals](https://www.zellic.io/blog/introducing-v12/). All issues found by V12 will be judged as out of scope and ineligible for awards.

V12 findings will typically be posted in this section within the first two days of the competition.  

## Publicly known issues

_Anything included in this section is considered a publicly known issue and is therefore ineligible for awards._

- Production config assumptions: `minDeposit = 1e16` and `minShare = 1e6`, and `MultiVault` enforces these floors. Findings that rely on `1 wei`style deposits or leaving vaults below minimum share floor should be treated as invalid under production params.
- `TrustBonding` intentionally has a single-epoch claim window; older rewards become unclaimable by users and are handled as unclaimed emissions.
- `AtomWallet` signature format is intentionally strict: only 65-byte raw ECDSA or 77-byte ECDSA+time-window suffix.
- Router behavior and configuration are intentional: `TrustSwapAndBridgeRouter` is constant-configured (TRUST/WETH/router/factory/quoter/hub/domain/gas/finality values embedded in contract code), has no owner/admin role, and exposes no admin setter functions. ERC20 flow refunds excess ETH sent with the transaction (`msg.value - bridgeFee`), while the ETH flow consumes `msg.value - bridgeFee` as swap input (no separate excess-refund path). Importantly,  `TrustSwapAndBridgeRouter` contract is intended to only ever be deployed on the Base mainnet (chain id 8453).

# Overview

**Intuition is a decentralized protocol for building the world's first open, semantic, and token-curated knowledge graph.** It provides the infrastructure for verifiable attestations, portable identity, and trustful interactions at scale—creating a universal data layer that enables information to flow freely across applications, blockchains, and AI agents.

## What is Intuition?
While blockchains have historically decentralized money, **Intuition decentralizes information**—specifically its trust, ownership, discoverability, and monetization. By transforming unstructured, siloed data into structured, verifiable, and economically-backed attestations, Intuition creates a Semantic Web of Trust that makes knowledge programmable and interoperable.

### Core Capabilities
**Universal Identity:** Decentralized identifiers (DIDs) for people, concepts, organizations, and AI agents with portable, self-sovereign identity management
**Verifiable Attestations:** Structured claims (subject-predicate-object triples) that are signed, attributable, and economically staked
**Knowledge Graph:** A semantic layer where facts and opinions coexist with verifiable provenance and economic signals
**Economic Incentives:** Bonding curves and cryptoeconomic mechanisms that align participants toward canonical standards and high-quality data

## Links

- **Previous audits:**  https://github.com/0xIntuition/intuition-contracts-v2/tree/main/audits
- **Documentation:** https://www.docs.intuition.systems/
- **Website:** https://www.intuition.systems/
- **X/Twitter:** https://x.com/0xIntuition

---

# Scope

### Files in scope

*See [scope.txt](https://github.com/code-423n4/2026-03-intuition/blob/main/scope.txt)*

*Note: The nSLoC counts in the following table have been automatically generated and may differ depending on the definition of what a "significant" line of code represents. As such, they should be considered indicative rather than absolute representations of the lines involved in each contract.*
| File | nSLOC |
| ---- | ----- |
| /src/protocol/emissions/TrustBonding.sol | 359 |
| /src/protocol/curves/ProgressiveCurve.sol | 83 |
| /src/protocol/curves/OffsetProgressiveCurve.sol | 86 |
| /src/protocol/wallet/AtomWallet.sol | 158 |
| /intuition-contracts-v2-periphery/contracts/TrustSwapAndBridgeRouter.sol | 158 |
| **Totals** | **844** |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2026-03-intuition/blob/main/out_of_scope.txt)*

| File |
| ---- |
| ./script/SetupScript.s.sol |
| ./script/base/BaseEmissionsControllerDeploy.s.sol |
| ./script/base/BaseEmissionsControllerSetup.s.sol |
| ./script/base/LegacyTrustTokenDeploy.s.sol |
| ./script/base/TrustDeploy.s.sol |
| ./script/e2e/HubBridgeDeploy.s.sol |
| ./script/e2e/SpokeBridgeDeploy.s.sol |
| ./script/intuition/DeployOffsetProgressiveCurve.s.sol |
| ./script/intuition/IntuitionDeployAndSetup.s.sol |
| ./script/intuition/MultiVaultDeploy.s.sol |
| ./script/intuition/MultiVaultMigrationModeDeploy.s.sol |
| ./script/intuition/MultiVaultMigrationUpgrade.s.sol |
| ./script/intuition/TrustBondingDeployAndSetup.s.sol |
| ./script/intuition/WrappedTrustDeploy.s.sol |
| ./script/periphery/DeployEntryPoint.s.sol |
| ./src/Trust.sol |
| ./src/WrappedTrust.sol |
| ./src/external/curve/VotingEscrow.sol |
| ./src/interfaces/IAtomWallet.sol |
| ./src/interfaces/IAtomWalletFactory.sol |
| ./src/interfaces/IAtomWarden.sol |
| ./src/interfaces/IBaseCurve.sol |
| ./src/interfaces/IBaseEmissionsController.sol |
| ./src/interfaces/IBondingCurveRegistry.sol |
| ./src/interfaces/ICoreEmissionsController.sol |
| ./src/interfaces/IMetaLayer.sol |
| ./src/interfaces/IMultiVault.sol |
| ./src/interfaces/IMultiVaultCore.sol |
| ./src/interfaces/ISatelliteEmissionsController.sol |
| ./src/interfaces/ITrust.sol |
| ./src/interfaces/ITrustBonding.sol |
| ./src/interfaces/ITrustUnlock.sol |
| ./src/interfaces/ITrustUnlockFactory.sol |
| ./src/legacy/TrustToken.sol |
| ./src/libraries/ProgressiveCurveMathLib.sol |
| ./src/protocol/MultiVault.sol |
| ./src/protocol/MultiVaultCore.sol |
| ./src/protocol/MultiVaultMigrationMode.sol |
| ./src/protocol/curves/BaseCurve.sol |
| ./src/protocol/curves/BondingCurveRegistry.sol |
| ./src/protocol/curves/LinearCurve.sol |
| ./src/protocol/emissions/BaseEmissionsController.sol |
| ./src/protocol/emissions/CoreEmissionsController.sol |
| ./src/protocol/emissions/MetaERC20Dispatcher.sol |
| ./src/protocol/emissions/SatelliteEmissionsController.sol |
| ./src/protocol/wallet/AtomWalletFactory.sol |
| ./src/protocol/wallet/AtomWarden.sol |
| ./tests/BaseTest.t.sol |
| ./tests/mocks/BaseEmissionsControllerMock.sol |
| ./tests/mocks/CoreEmissionsControllerMock.sol |
| ./tests/mocks/ERC20Mock.sol |
| ./tests/mocks/MetalayerRouterMock.sol |
| ./tests/mocks/TestTrust.sol |
| ./tests/mocks/TrustBondingMock.sol |
| ./tests/mocks/VotingEscrowHarness.sol |
| ./tests/testnet/HubBridge.sol |
| ./tests/testnet/SpokeBridge.sol |
| ./tests/unit/AtomWallet/AtomWallet.t.sol |
| ./tests/unit/AtomWarden/AtomWarden.t.sol |
| ./tests/unit/BaseEmissionsController/AccessControl.t.sol |
| ./tests/unit/BaseEmissionsController/MintAndBridge.t.sol |
| ./tests/unit/BaseEmissionsController/MintAndBridgeCurrentEpoch.t.sol |
| ./tests/unit/BaseEmissionsController/Reads.t.sol |
| ./tests/unit/CoreEmissionsController/CoreEmissionsControllerBase.t.sol |
| ./tests/unit/CoreEmissionsController/Reads.t.sol |
| ./tests/unit/MultiVault/AdminFunctions.t.sol |
| ./tests/unit/MultiVault/ClaimFees.t.sol |
| ./tests/unit/MultiVault/CounterStakeGuard.t.sol |
| ./tests/unit/MultiVault/CreateAtoms.t.sol |
| ./tests/unit/MultiVault/CreateTriples.t.sol |
| ./tests/unit/MultiVault/Deposit.t.sol |
| ./tests/unit/MultiVault/DepositBatch.t.sol |
| ./tests/unit/MultiVault/FeeFlows.t.sol |
| ./tests/unit/MultiVault/Helpers.t.sol |
| ./tests/unit/MultiVault/Redeem.t.sol |
| ./tests/unit/MultiVault/RedeemBatch.t.sol |
| ./tests/unit/MultiVault/UtilizationTest.t.sol |
| ./tests/unit/MultiVaultCore/MultiVaultCore.t.sol |
| ./tests/unit/MultiVaultMigrationMode/MultiVaultMigrationMode.t.sol |
| ./tests/unit/SatelliteEmissionsController/AccessControl.t.sol |
| ./tests/unit/SatelliteEmissionsController/BridgeUnclaimedEmissions.t.sol |
| ./tests/unit/SatelliteEmissionsController/Reads.t.sol |
| ./tests/unit/SatelliteEmissionsController/WithdrawUnclaimedEmissions.t.sol |
| ./tests/unit/Trust/LegacyTrustToken.t.sol |
| ./tests/unit/Trust/Trust.t.sol |
| ./tests/unit/Trust/TrustUpgradeIntegrationTest.t.sol |
| ./tests/unit/Trust/WrappedTrust.t.sol |
| ./tests/unit/TrustBonding/AccessControl.t.sol |
| ./tests/unit/TrustBonding/ClaimRewards.t.sol |
| ./tests/unit/TrustBonding/Events.t.sol |
| ./tests/unit/TrustBonding/Getters.t.sol |
| ./tests/unit/TrustBonding/NormalizedUtilizationRatio.t.sol |
| ./tests/unit/TrustBonding/Reads.t.sol |
| ./tests/unit/TrustBonding/TrustBonding.t.sol |
| ./tests/unit/TrustBonding/TrustBondingBase.t.sol |
| ./tests/unit/TrustBonding/TrustBondingIntegration.t.sol |
| ./tests/unit/TrustBonding/TrustBondingRegressionTest.t.sol |
| ./tests/unit/TrustBonding/UserAndSystemUtilizationRatio.t.sol |
| ./tests/unit/TrustBonding/reads/BalanceOf.t.sol |
| ./tests/unit/TrustBonding/reads/GetUserCurrentClaimableRewards.t.sol |
| ./tests/unit/TrustBonding/reads/GetUserInfo.t.sol |
| ./tests/unit/TrustBonding/reads/GetUserRewardsForEpoch.t.sol |
| ./tests/unit/TrustBonding/reads/SystemApy.t.sol |
| ./tests/unit/TrustBonding/reads/UserApy.t.sol |
| ./tests/unit/TrustBonding/reads/UserClaimedRewardsForEpoch.t.sol |
| ./tests/unit/VotingEscrow/VotingEscrow.t.sol |
| ./tests/unit/VotingEscrow/VotingEscrowBinarySearch.t.sol |
| ./tests/unit/VotingEscrow/VotingEscrowVievHelpersIntegration.t.sol |
| ./tests/unit/curves/BondingCurveRegistry.t.sol |
| ./tests/unit/curves/LinearCurve.t.sol |
| ./tests/unit/curves/OffsetProgressiveCurve.t.sol |
| ./tests/unit/curves/OffsetProgressiveCurveConfiguration.t.sol |
| ./tests/unit/curves/ProgressiveCurve.t.sol |
| ./tests/utils/Constants.sol |
| ./tests/utils/Modifiers.sol |
| ./tests/utils/Types.sol |
| ./tests/utils/Utils.sol |
| ./intuition-contracts-v2-periphery/tests/utils/* |
| ./intuition-contracts-v2-periphery/tests/mocks/* |
| ./intuition-contracts-v2-periphery/tests/TrustSwapAndBridgeRouter/* |
| ./intuition-contracts-v2-periphery/tests/EmissionsAutomationAdapter/* |
| ./intuition-contracts-v2-periphery/tests/* |
| ./intuition-contracts-v2-periphery/script/uniswap-v3-setup/* |
| ./intuition-contracts-v2-periphery/script/system/* |
| ./intuition-contracts-v2-periphery/script/* |
| ./intuition-contracts-v2-periphery/contracts/interfaces/external/uniswapv3/* |
| ./intuition-contracts-v2-periphery/contracts/interfaces/external/metalayer/* |
| ./intuition-contracts-v2-periphery/contracts/interfaces/external/chainlink/* |
| ./intuition-contracts-v2-periphery/contracts/interfaces/external/aerodrome/* |
| ./intuition-contracts-v2-periphery/contracts/interfaces/external/* |
| ./intuition-contracts-v2-periphery/contracts/interfaces/* |
| ./intuition-contracts-v2-periphery/contracts/EmissionsAutomationAdapter.sol |
| Totals: 132 |

# Additional context

## Areas to focus (differential changes)
- Full files remain in scope for maximum competition coverage. The following line ranges are where the differential changes occurred and are recommended focus areas.
- `TrustBonding.sol`: lines `335-340` (unclaimed rewards calculation semantics).
- `ProgressiveCurve.sol`: line `240` (math update).
- `OffsetProgressiveCurve.sol`: line `247` (math update).
- `AtomWallet.sol`: lines `285-311` (signature validation logic) and `337-361` (`validUntil`/`validAfter` extraction from signature).
- `TrustSwapAndBridgeRouter.sol` (periphery): entire contract is in scope; focus on packed path parsing/pool validation, bridge fee handling, and external call sequencing across swap + bridge flows.

## Main invariants

- Router path invariants: ETH path must start with WETH and all paths must end with TRUST; all hops must map to existing pools before swap.
- Router fee/value invariants: swap/bridge reverts if bridge fee is insufficient; ERC20 flow refunds all ETH above required bridge fee.
- Router config invariants: there is no owner/admin control path; router/factory/quoter/bridge configuration is compile-time `constant` data.

- AtomWallet auth invariant: only `owner()` or `EntryPoint` can execute wallet actions; deposit withdrawal is only by owner or self-call.
- `AtomWallet` signature invariant: validation only accepts 65/77-byte signatures; time-window metadata is interpreted from signature suffix (PR [#135](https://github.com/0xIntuition/intuition-contracts-v2/pull/135) behavior).
- `TrustBonding` claim-window invariant: only previous epoch is user-claimable; cannot double-claim an epoch.
- `TrustBonding` unclaimed invariant: for epochs outside claim window, unclaimed amount is based on max epoch emissions minus claimed (PR [#134](https://github.com/0xIntuition/intuition-contracts-v2/pull/134) behavior).
- Curve math invariant: redeem/convert-to-assets path uses consistent conservative rounding and must not revert in low-share edge cases where result should be zero (PR #136 behavior).
- System config invariant: effective deployment assumptions include `minDeposit`/`minShare` floors mentioned above (no dust-state vault behavior below floor).

## All trusted roles in the protocol

| Role | Description |
| ---- | ----------- |
| `TrustSwapAndBridgeRouter` | No privileged runtime role. The contract is not `Ownable`; router/factory/quoter/bridge configuration values are embedded as `constant`s and cannot be changed via admin setters. |
| `TrustBonding` — `timelock` | Controls parameter updates; minimum delay of 3 days. |
| `TrustBonding` — `DEFAULT_ADMIN_ROLE` | Admin and unpause rights; also inherits `VotingEscrow` admin actions. |
| `TrustBonding` — `PAUSER_ROLE` | Can only pause the contract. |
| `AtomWallet` — `owner` | Initially `AtomWarden` (via `MultiVault`) until claimed by the user, who then assumes full wallet ownership. |
| `AtomWallet` — `EntryPoint` | Trusted ERC-4337 entry point contract; sole authorized caller for the account abstraction execution path. |
| `ProgressiveCurve` / `OffsetProgressiveCurve` — upgrade/init authority | No runtime privileged role in normal operation. Upgrade and initialization authority is managed at the proxy/governance layer via timelock (minimum delay of 7 days). |

## Running tests

- If Foundry is not already installed: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- If Bun is not already installed, see: https://bun.com/docs/installation
- Optional: Fork tests require Alchemy RPC config, so please make sure to set `API_KEY_ALCHEMY` in your local `.env` file (or skip fork tests when running locally without RPC).

```bash
git clone --recurse https://github.com/code-423n4/2026-03-intuition.git
cd code-423n4/2026-03-intuition
forge install && bun install
forge build
forge test
cd intuition-contracts-v2-periphery
forge install && bun install
forge build
forge test
```

## Creating a PoC

High- and Medium-risk submissions require a [coded, runnable Proof of Concept](https://docs.code4rena.com/competitions/submission-guidelines#required-proof-of-concept-poc-for-solidity-evm-audits). This repo provides `BaseTest` contract and two PoC templates under `tests/` so wardens can build PoCs against the same setup as the existing test suite.

### Core in-scope contracts (TrustBonding, ProgressiveCurve, OffsetProgressiveCurve, AtomWallet)

- **BaseTest:** [tests/BaseTest.t.sol](tests/BaseTest.t.sol) — deploys the protocol (Trust, WrappedTrust, MultiVault, TrustBonding, curves, AtomWallet factory, etc.) and exposes `protocol.*` and `users.*` (admin, alice, bob, charlie, timelock, controller).
- **PoC template:** [tests/PoCCore.t.sol](tests/PoCCore.t.sol)

Use `protocol.*` and `users.*` and add modifiers from BaseTest/Modifiers (e.g. `onlyAdmin`, `onlyUser`) as needed.

### Periphery in-scope contract (TrustSwapAndBridgeRouter)

- **Same BaseTest** as above (core protocol is available).
- **PoC template:** [tests/PoCPeriphery.t.sol](tests/PoCPeriphery.t.sol) — extends BaseTest and deploys `TrustSwapAndBridgeRouter`; implement your PoC in `test_submissionValidity()` (e.g. path validation, bridge fee handling, swapAndBridgeWithETH / swapAndBridgeWithERC20 / bridgeTrust).

### Running the PoC tests

From the **repo root** (no need to `cd` into periphery):

```bash
# Core PoC only
forge test --match-contract PoCCore --match-test submissionValidity

# Periphery PoC only
forge test --match-contract PoCPeriphery --match-test submissionValidity

# Both PoCs
forge test --match-test submissionValidity
```

The test **must execute successfully** for your submission to be considered valid.

## Miscellaneous
Employees of Intuition and employees' family members are ineligible to participate in this audit.

Code4rena's rules cannot be overridden by the contents of this README. In case of doubt, please check with C4 staff.
