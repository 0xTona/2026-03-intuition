## Intuition Core (Main Repo)

### Core Purpose

Intuition core contracts implement a tokenized trust layer where users lock TRUST to get time-weighted voting power
(veTRUST), then earn epoch-based emissions influenced by utilization in MultiVault. The same system also supports
atom-bound smart accounts and share/asset pricing via curve contracts used by MultiVault vaults.

### Actors & Roles

- TRUST locker: creates and manages veTRUST locks, then claims emissions.
- TRUST reward claimant: claims previous-epoch rewards to any recipient.
- Atom owner: eventually owns an `AtomWallet` and can execute arbitrary calls.
- AtomWarden: temporary owner of unclaimed `AtomWallet` accounts.
- EntryPoint (ERC-4337): authorized caller path for account-abstraction wallet execution.
- Timelock: updates key `TrustBonding` parameters and linked contract addresses.
- Admin/Pauser roles: pause or unpause `TrustBonding`; admin can also use inherited VotingEscrow controls.
- MultiVault: source of system/personal utilization data and atom-wallet fee accounting.
- SatelliteEmissionsController/CoreEmissionsController: provides epoch schedule, emissions, and reward token transfers.

### Contracts

- `TrustBonding`: veTRUST rewards engine (epoch math, utilization-adjusted emissions, claim accounting).
- `VotingEscrow` (inherited by `TrustBonding`): lock lifecycle (`create_lock`, `increase_amount`,
  `increase_unlock_time`, `withdraw`).
- `AtomWallet`: ERC-4337-compatible account tied to atom `termId`, with owner/EntryPoint gated execution.
- `ProgressiveCurve`: monotonic progressive pricing for shares/assets conversion.
- `OffsetProgressiveCurve`: progressive pricing with initial offset to shift early-share pricing.

### Terminology

- `veTRUST`: time-decaying bonded voting/reward weight derived from locked TRUST.
- `epoch`: emissions accounting period returned by emissions controller contracts.
- `system utilization`: epoch-over-epoch utilization delta at protocol level from `MultiVault`.
- `personal utilization`: user-level utilization delta from `MultiVault`.
- `claim window`: only previous epoch is claimable; older user rewards are forfeited.
- `termId`: identifier for an atom/triple context; used by `AtomWallet` to claim deposit fees.

### Key Invariants

- Rewards are claimable only for `currentEpoch - 1`, once per user per epoch.
- Epoch 0 has no reward claiming; epochs 0 and 1 use full utilization ratio.
- For old, non-claimable epochs, unclaimed rewards are computed from max epoch emissions minus already claimed totals.
- `TrustBonding` utilization ratios are always bounded by configured lower bounds and `BASIS_POINTS_DIVISOR`.
- `TrustBonding` timelock-only setters gate `multiVault`, `timelock`, satellite controller, and utilization lower
  bounds.
- `AtomWallet.execute()` and `AtomWallet.executeBatch()` are callable only by wallet owner or `EntryPoint`.
- `AtomWallet.owner()` resolves to `AtomWarden` until `acceptOwnership()` marks wallet as claimed.
- `AtomWallet` signatures must be exactly 65 bytes (raw ECDSA) or 77 bytes (ECDSA plus `validUntil`/`validAfter`
  suffix).
- Curve conversions enforce domain and bounds checks (`MAX_SHARES`, `MAX_ASSETS`) and conservative rounding behavior.
- VotingEscrow lock lifecycle enforces minimum lock duration, max lock duration, and no early withdrawal unless globally
  unlocked by admin.

### Main Assets

- `TRUST` (locked principal and reward token)
- `veTRUST` bonded balances and epoch snapshots
- `totalClaimedRewardsForEpoch`
- `userClaimedRewardsForEpoch`
- EntryPoint deposit ETH held on `IEntryPoint`
- Atom wallet deposit fees claimable from `MultiVault`
- Vault `totalAssets` and `totalShares` values priced by curve contracts

### Happy Paths

Path 1 - Lock TRUST and claim emissions 1.1. User -> `VotingEscrow.create_lock()`: lock TRUST for a time period and
initialize veTRUST position. 1.2. User -> `VotingEscrow.increase_amount()` or `VotingEscrow.increase_unlock_time()`:
raise principal and/or extend lock horizon. 1.3. User -> `TrustBonding.claimRewards()`: claim previous-epoch TRUST
rewards after utilization adjustment.

Path 2 - End lock and exit 2.1. User -> `VotingEscrow.withdraw()`: withdraw locked TRUST after lock expiry. 2.2. User ->
`VotingEscrow.withdraw_and_create_lock()`: roll position by withdrawing and immediately creating a new lock.

Path 3 - Atom wallet lifecycle and execution 3.1. AtomWarden/User -> `AtomWallet.transferOwnership()`: set pending owner
for atom-bound smart account. 3.2. Pending owner -> `AtomWallet.acceptOwnership()`: claim account ownership and flip
`isClaimed`. 3.3. Owner or EntryPoint -> `AtomWallet.execute()` or `AtomWallet.executeBatch()`: run wallet operations.
3.4. Owner -> `AtomWallet.claimAtomWalletDepositFees()`: pull atom fee accruals from `MultiVault`.

Path 4 - Curve-driven vault pricing 4.1. MultiVault-integrated caller -> `ProgressiveCurve.convertToShares()` or
`OffsetProgressiveCurve.convertToShares()`: price share mint for deposit assets. 4.2. MultiVault-integrated caller ->
`ProgressiveCurve.convertToAssets()` or `OffsetProgressiveCurve.convertToAssets()`: price redemption assets for burned
shares. 4.3. MultiVault-integrated caller -> `ProgressiveCurve.currentPrice()` or
`OffsetProgressiveCurve.currentPrice()`: read marginal share price.

### External Dependencies

- `IMultiVault`: provides utilization series and atom-wallet fee accounting. Assumption: utilization getters are
  consistent across epochs and cannot be manipulated out-of-band for a finalized epoch.
- `ISatelliteEmissionsController` and `ICoreEmissionsController`: epoch timing, max emissions, and reward transfers.
  Assumption: epoch boundaries and emissions values are monotonic/consistent and transfer calls reliably mint or move
  TRUST rewards.
- `IERC20` TRUST token in VotingEscrow path. Assumption: TRUST follows expected ERC20 transfer semantics and does not
  apply unexpected fee-on-transfer logic for lock operations.
- `IEntryPoint` (ERC-4337) integration in `AtomWallet`. Assumption: trusted EntryPoint address is correct and stable for
  account-abstraction security.
- OpenZeppelin ECDSA recover behavior. Assumption: upstream ECDSA validation and malleability checks remain standard and
  unchanged.
