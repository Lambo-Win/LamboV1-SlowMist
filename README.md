## LaunchPad in fair launch


### Project Requirements

Meme LaunchPad, where anyone can deploy their own tokens for a LaunchPad issuance. The requirements are as follows:

1. When raising 4.2 ETH, be able to fully distribute 0.7 billion Meme Tokens; 0.3 billion Meme Tokens will be paired with the raised ETH to create a trading pair on Uniswap; 

2. The initial price and the final price of the LaunchPad should have a multiplier of approximately 7.

3. The external market price must always be higher than the initial and final prices of the LaunchPad, ensuring that all LaunchPad participants are profitable and will not incur losses. The maximum profit margin, as indicated by the external market price/initial LaunchPad price ratio, should be around 11 to 12 times.

4. The overall design is a multi-modular Modular LaunchPad, with a multi-factory -> pool -> router architecture that supports the addition of any LaunchPad curve in the future.

5. The internal platform fee will only be charged in ETH/USDT/USDi (base tokens), so the final amount received will be less than 4.2 ETH (as some will be transferred to the Vault as fees).

6. After the liquidity crowdfunding is completed, the admin will trigger the migration to perform the liquidity migration.

### Contract Architecture
The overall contract adopts a multi-factory -> pool -> router architecture:

[![Contract Architecture]("https://github.com/Lambo-Win/LamboV1-SlowMist/tree/main/pic/framework.png")]()

1. Factory: Used to create LaunchPools.

2. LaunchPool: Implements the exchange algorithm.

3. Vault: Stores 30% of the Meme Tokens, used for external market listings and reward distribution.

4. Router: Exchange routing.

5. Factory Register: Factory whitelist (used to verify the Pool parameters for the Router).