## TrustBonding.sol

### Compressed & Grouped State (labels)

- **Rewards accounting**:
  - `totalClaimedRewardsForEpoch` *(epoch → totalClaimed)*
  - `userClaimedRewardsForEpoch` *(user → epoch → claimed)*

- **External integrations**:
  - `multiVault`
  - `satelliteEmissionsController`

- **Utilization config**:
  - `systemUtilizationLowerBound`
  - `personalUtilizationLowerBound`

- **Access control**:
  - `timelock`

- **Upgrade safety**:
  - `__gap`

---

### Inherited from VotingEscrow (frequently referenced)

- **Lock state**:
  - `locked` *(address → LockedBalance{amount, end})*
  - `supply`
  - `unlocked`

- **Epoch / checkpoint**:
  - `epoch`
  - `point_history` *(epoch → Point{bias, slope, ts, blk})*
  - `user_point_history` *(address → Point[])*
  - `user_point_epoch` *(address → uint256)*
  - `slope_changes` *(time → int128)*

- **Config**:
  - `token`
  - `MINTIME`
  - `controller`
  - `transfersEnabled`
  - `contracts_whitelist` *(address → bool)*
