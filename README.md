# LightPad

- [LightPad](#lightpad)
  - [Techstack](#techstack)
    - [Interface](#interface)
    - [Smart Contract](#smart-contract)
  - [Features](#features)
  - [Smart Contract Functions](#smart-contract-functions)

## Techstack

### Interface
- React (with Vite)
- Tailwind CSS
- Ant Design
- Web3 Modal
- Wagmi
- Viem
  
### Smart Contract
Deployed Contract: [0x633B8017071aD4B339aC2F70656f79B3901e4a68](https://pegasus.lightlink.io/address/0x633B8017071aD4B339aC2F70656f79B3901e4a68?tab=contract) (contracts/src/LP.sol)

-  Foundry
-  API3 Airnode (QRNG)
-  OpenZeppelin

## Features
- **Protocol Owner's Role:**
  - The protocol owner can initiate IDO sales for projects participating in the protocol.
- **Investor Participation Phases:**
  -  **Phase 1: Staking** 
     - Users can stake LPT tokens to join the whitelist.
     - Two Tiers based on staking:
       - Tier 1: Average staking of 1-299 LPT tokens with over 10 days average staking time. Eligible for the whitelist lottery.
       - Tier 2: Average staking of 300 or more LPT tokens with over 10 days average staking time. Guaranteed allocation, with more tokens and longer staking time leading to increased allocation.
  -  **Phase 2: Tier Division** 
     -  The protocol owner will execute functions in the smart contract to categorize users into tiers. Whitelist information for Tier 1 will be announced through official protocol channels.
  -  **Phase 3: Purchase** 
     -  Tokens will be sold for stablecoins (e.g., USDT, USDC, or DAI). Users must prepare stablecoin tokens in advance for IDO participation.
  -  **Phase 4: Claim** 
     -  After completing Phase 3, users can claim their tokens to their wallets and trade them on available decentralized exchanges (DEXs).

## Smart Contract Functions

Technically, the smart contract will include the following functions:

- Owner function:
  - `LightPad::createIDO()` allows `owner` to create a new project to start IDO.
  - `LightPad::setIDOPhase()` allows `owner` to change the phases of an IDO`.
- User function:
  - `LightPad::staking()` allows `users` to stake their LPT tokens to participate in an IDO.
  - `LightPad::purchase()` allows `users` to purchase tokens of an IDO project with a calculated allocation.
  - `LightPad::claim()` allows `users` to receive their tokens after passing phase 3.

Updating...