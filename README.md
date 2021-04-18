# Vlad Finance

https://vlad.finance 

https://t.me/VladFinanceOfficial

https://vlad-finance.medium.com/

https://twitter.com/VladFinance


## Deployed Contracts / Hash

### BSCMAINNET

LP token to farm Life:

- VladToken - https://bscscan.com/token/0x279d41f3f78fe5c1f0ba41ae963d6e545113c973
  
- Buy Vlad: https://exchange.pancakeswap.finance/#/swap?outputCurrency=0x279d41f3f78fe5c1f0ba41ae963d6e545113c973 
  

- AfterLife - https://bscscan.com/token/0x0
- MasterChef - https://bscscan.com/address/0x0
- Timelock - https://bscscan.com/address/0x0
- MultiCall - https://bscscan.com/address/0x0


### BSCTESTNET

- AfterLife - https://testnet.bscscan.com/address/0xADA2270B0CB5b6254d3d48A6fEE55b72693B746A#code
- MasterChef - https://testnet.bscscan.com/address/0xE37Aa693d2Ab77721E11e55bfBC723cf4457b78E#code
- VladToken - https://testnet.bscscan.com/address/0x5Ef22E12B661de51c4f103ed607AA30FFEf7ed09#code
  (for test only)

# NftFarm.sol

### adminSetInterval

`adminSetInterval(uint256 _start, uint256 _end)`

Manage the start and the end of nft minting.

- _start: start block.
- _end: end block.

### adminChangeToken

`adminChangeToken(address _token)`

Allow to change the token used to buy NFT's.

### adminSetTotalSupply

`adminSetTotalSupply(uint256 _totalSupplyDistributed)`

Allow to control the max total amount of NFT that can be minted globally.

- _totalSupplyDistributed: max number of mintable nfts, ex: 10000

### adminSetTokenPerBurn

`adminSetTokenPerBurn(uint256 _tokenPerBurn)`

Set the global amount of token to burn on each nft ming.

Note: use WEI here, example: convert 1 token to `1000000000000000000`, use the site https://eth-converter.com/ to convert 1 ETH to `1000000000000000000` WEI.

### adminSetBaseURI

`adminSetBaseURI(string memory _baseURI)`

Allow change of root ipfs uri.

### adminSetPriceByNftId

`adminSetPriceByNftId(uint8 _nftId, uint256 _price)`

Allow change of the price of one NFT.

- _nftId: the nft index id from gallery.
- _price: the price in wei.

### adminSetMintingManager

`adminSetMintingManager(address _manager, bool _status)`

Manage the minters, minters can set the nft price per nft index via `adminSetPriceByNftId`

### adminSetMultiplier

`adminSetMultiplier(uint256 _priceMultiplier)`

Allow the management of multiplier if multiplier nft minting is enabled for one nft.

Ie: for every new same nft mint it increments the price by amount and by this multiplier.

ex: `1*1*1.1=1.1, 1*2*1.1=2,2 ... 1*10*1.1=111`

- _priceMultiplier: the multiplier factor.

### adminSetAllowMultipleClaims

`adminSetAllowMultipleClaims(bool _status)`

Allow multiple nft minting by same nft index.

### adminSetMaxMintPerNft

`adminSetMaxMintPerNft(uint256 _maxMintPerNft)`

Manage the max amount to mint for each nft globally.

### adminSetMintingInterval

`adminSetMintingInterval(uint8 _min_index, uint8 _max_index)`

Indicates the interval index allowed to mint NFTs.

For example: adminSetMintingInterval(0, 2)

Allow to mint NFT from position 0 upt 2, or first 3 nfts in the gallery.

To add more NFTs change to adminSetMintingInterval(0, 5) to allow minting of the first 6 nfts in the gallery.
