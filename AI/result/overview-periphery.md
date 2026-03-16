## Intuition Periphery (Swap and Bridge)

### Core Purpose

The periphery router on Base swaps ETH or ERC20 inputs into TRUST through Slipstream paths, then bridges TRUST to
Intuition mainnet through Metalayer. It is intentionally minimal and stateless at runtime, with all critical integration
addresses embedded as constants.

### Actors & Roles

- End user: provides ETH or ERC20 input and bridge fee to move value into TRUST on destination chain.
- `TrustSwapAndBridgeRouter`: validates path, executes swap, and calls bridge transport.
- Slipstream SwapRouter: executes exact-input swaps.
- Slipstream CL Factory: source of pool-existence checks for each hop in packed path.
- Slipstream Quoter: optional off-chain-like quote endpoint wrapped by contract.
- WETH contract: wraps ETH for ETH-input swap path.
- MetaERC20Hub: receives TRUST and emits cross-chain transfer (`transferId`).
- Recipient on Intuition domain: target account encoded as bytes32.

### Contracts

- `TrustSwapAndBridgeRouter`: only in-scope periphery execution contract (swap-plus-bridge and direct bridge).

### Terminology

- `packed path`: `tokenA | tickSpacing | tokenB | ...` hop encoding used by Slipstream.
- `bridge fee`: ETH quoted by `MetaERC20Hub.quoteTransferRemote()` required for bridge execution.
- `recipientDomain`: fixed destination domain ID for Intuition mainnet.
- `finalityState`: bridge finality mode sent to Metalayer.
- `transferId`: bridge operation identifier returned by `transferRemote()`.

### Key Invariants

- ETH path must start with WETH and end with TRUST.
- ERC20 path must start with `tokenIn` and end with TRUST.
- Path length and hop encoding must satisfy packed-path format constraints.
- Every hop in path must map to a nonzero pool in Slipstream CL factory.
- ETH entrypoint requires `msg.value > bridgeFee` so there is positive swap input.
- ERC20/direct bridge entrypoints require `msg.value >= bridgeFee`.
- ERC20 and direct TRUST bridge flows refund exact ETH excess (`msg.value - bridgeFee`).
- ETH flow uses all ETH above bridge fee as swap input (no separate excess refund path).
- No owner/admin mutators exist; router/factory/quoter/hub/domain/finality/gas constants are immutable in bytecode.
- Router reentrancy guard wraps all mutative public entrypoints.

### Main Assets

- `ETH` (`msg.value`)
- `WETH` (wrapped swap input in ETH route)
- `tokenIn` (ERC20 input in token route)
- `TRUST` (swap output and bridged asset)
- Bridge fee ETH sent to Metalayer
- `transferId` returned by bridge call

### Happy Paths

Path 1 - ETH to TRUST and bridge 1.1. User -> `TrustSwapAndBridgeRouter.swapAndBridgeWithETH()`: submit packed path, min
TRUST out, recipient, and ETH value. 1.2. Router -> `IWETH.deposit()`: wrap ETH amount reserved for swap. 1.3. Router ->
`ISlipstreamSwapRouter.exactInput()`: swap WETH path output into TRUST. 1.4. Router -> `IMetaERC20Hub.transferRemote()`:
bridge TRUST to recipient domain and emit transfer ID.

Path 2 - ERC20 to TRUST and bridge 2.1. User -> `TrustSwapAndBridgeRouter.swapAndBridgeWithERC20()`: submit token input
amount, path, recipient, and bridge fee ETH. 2.2. Router -> `IERC20.safeTransferFrom()`: pull ERC20 input from user.
2.3. Router -> `ISlipstreamSwapRouter.exactInput()`: swap input token path output into TRUST. 2.4. Router ->
`IMetaERC20Hub.transferRemote()`: bridge TRUST and produce transfer ID. 2.5. Router -> internal refund branch: return
ETH excess above required bridge fee.

Path 3 - Direct TRUST bridge 3.1. User -> `TrustSwapAndBridgeRouter.bridgeTrust()`: provide TRUST amount, recipient, and
bridge fee ETH. 3.2. Router -> `IERC20.safeTransferFrom()`: pull TRUST into router. 3.3. Router ->
`IMetaERC20Hub.transferRemote()`: bridge TRUST to destination recipient. 3.4. Router -> internal refund branch: return
ETH excess above required bridge fee.

Path 4 - Quoting before execution 4.1. Caller -> `TrustSwapAndBridgeRouter.quoteExactInput()`: estimate TRUST output for
packed path and amount. 4.2. Caller -> `TrustSwapAndBridgeRouter.quoteBridgeFee()`: estimate ETH bridge fee for
recipient and TRUST amount.

### External Dependencies

- Slipstream contracts (`SwapRouter`, `CLFactory`, `Quoter`). Assumption: factory pool lookup and swap execution
  semantics match encoded path expectations and cannot be spoofed by alternate routers.
- `IWETH` at canonical Base WETH address. Assumption: deposit and transfer behavior is standard and non-malicious.
- `IMetaERC20Hub` bridge transport. Assumption: quoted bridge fee is sufficient for `transferRemote()` under same state
  conditions and destination domain is correctly configured.
- TRUST ERC20 token. Assumption: TRUST transfer and allowance semantics are ERC20-compliant and do not break
  `safeIncreaseAllowance` plus bridge pull flow.
