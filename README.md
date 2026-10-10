# ArcSplit

Split native USDC across N recipients in one transaction on [Arc](https://www.circle.com/arc) (Circle's L1, chain ID 5042).

On Arc the gas token **is** USDC, so the dollars you split are paid for with the dollars you hold. No separate gas token, no wrapping, no extra steps. ArcSplit is the smallest useful expression of that idea: one call, N recipients, pro-rata by share weights.

## How it works

`split(address[] recipients, uint256[] shares)` payable:
- Validates inputs (matching lengths, no zero addresses, nonzero total shares)
- Sends each recipient `msg.value * share / totalShares`
- Refunds integer-division dust to the sender
- Reentrancy-guarded, emits a `Split` event

`sweep()` lets the owner recover any stranded balance.

## Run it

```bash
forge build
forge test
```

## Deploy (Arc mainnet)

```bash
export ARC_RPC_URL="https://rpc.mainnet.arc.io"   # or your provider endpoint
forge script script/Deploy.s.sol --rpc-url $ARC_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

Then paste the deployed address into `frontend/index.html` (`CONTRACT`) and open it in a browser with a wallet.

## Why this fits Arc Microgrants

Tiny, real, demoable. It does one thing on the chain Arc was built for — moving dollars — and it works for first-time Arc deployers with standard EVM tooling (Foundry, no changes needed).

Built for the [Arc Microgrants](https://dorahacks.io/hackathon/arc-microgrants/detail) program (Circle via DoraHacks).
