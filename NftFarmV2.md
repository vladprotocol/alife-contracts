# Vlad VNFT Primary Marktplace

Allow nft to be minted/sell in the by authors.
Once a nft is added it can be minted in a specific amount in a period of time at specific price.

# Vlad VNFT Secondary Marktplace

Allow users to put a minted nft to sell if allowed to, other users can the buy this nft.

# Vlad VNFT Tertiary Marktplace 

*(not implemented yet).* Allow management to put a nft in auction mode.

# Vlad VNFT Transer

Allow a user to transfer a nft, if allowed to. Like to gift a nft to someone.

---

# Vlad NFT Management

*This are functions used to manage nft minting factory and marketplace by allowed managers.*

## add 
*Allow  marketplace to manage nft availbility in the marketplace.*

Options when adding a new NFT:

- **_nftId**: unique number for this nft.
- **_author**: for author to receive funds and manage his nft if allowed.
- **_startBlock/_endBlock**: determine block interface that this nft can be minted.
- **_allowMng**: if true, allow author to manage some info of this nft, like name, twitter, etc.
- **_rarity**: the category of this nft. 
- **_uri**: the base url can be https or ipfs pin url.
- **_authorFee**: the fee to be paid on each minting for the author.
- **_authorName**: the name or nickname.
- **_authorTwitter**: the author Twitter account.
- **_status**: true to enabled this nft minting.


```solidity
add(uint8 _nftId, address _author,
uint256 _startBlock, uint256 _endBlock, bool _allowMng,
string memory _rarity, string memory _uri, uint256 _authorFee,
string memory _authorName, string memory _authorTwitter, uint256 _status)
external
mintingManagers
```

## set
*Allow management to update some NFT info. Arguments are same of add.*

Options when changing a new NFT are:

- **_nftId**: id number of an existing nft.
- **_author**: for author to receive funds and manage his nft if allowed.
- **_startBlock/_endBlock**: determine block interface that this nft can be minted.
- **_allowMng**: if true, allow author to manage some info of this nft, like name, twitter, etc.
- **_rarity**: the category of this nft.
- **_uri**: the base url can be https or ipfs pin url.
- **_authorFee**: the fee to be paid on each minting for the author.
- **_authorName**: the name or nickname.
- **_authorTwitter**: the author Twitter account.
- **_status**: true to enabled this nft minting.

```solidity
set(uint8 _nftId, address _author,
uint256 _startBlock, uint256 _endBlock, bool _allowMng,
string memory _rarity, string memory _uri, uint256 _authorFee,
string memory _authorName, string memory _authorTwitter)
external
mintingManagers
```

## setState
*Allow management to manage nft marketplace configuration. The reason for a marketplace state management is because solidity limit the amount of function arguments to add/set functions.*

Options:

- **_nftId**: id number of an existing nft.
- **_price**: control initial price for this nft, if nft minting uses bonding curve, this price get updated on every mint.
- **_maxMint**: the max amount of mint that this nft can be minted.
- **_multiplier**: exponential factor used in the bonding curve.

```solidity
setState(uint8 _nftId, uint256 _price,
uint256 _maxMint, uint256 _multiplier)
external
mintingManagers
```

## adminSetNftTokenMarket
*Allow management to manage the nft contract used to mint nft and bep20/erc20 contract used to pay for this nft. This allow marketplace to operate independently of nft contract and token buy asset.*

Options:

- **nftId**: id number of an existing nft. 
- **_nft**: any nft that implement VNFT interface. 
- **_token**: any bep20/erc20 that can be used to pay for each nft minting/burn, etc. 

## Additional admin functions

- adminSetgovFeeAddr: change governance treasure address.
- adminSetdevFeeAddr: change development treasure address.
- adminSetMintingManager: allow admin to add a new nft manager (users that can add/set nft in the marketplace).
- adminSetPlatformFee: allow to manage all primary marketplace fees, this are fees when the nft is minted for first time.
- adminSetMarketFee: allow to manage all secondary sell/buy fees, this are fees when user put a nft to sell.


# NFT Marketplace Information

## getNftByAuthor

Fetch all nft information and state by author name.

```solidity
getNftByAuthor(string memory author) public view returns
    (NftInfo[] memory info, NftInfoState[] memory state)
```

## getNftByRarity

Fetch all nft information and state by rarity (category) name.

```solidity
getNftByRarity(string memory rarity) public view returns
    (NftInfo[] memory, NftInfoState[] memory)
```

## getNftIdByUser

Fetch all nft id for a specific user (wallet).

```solidity
getNftIdByUser(address user)
public view returns (uint8[] memory)
```

## getTradesByNftIdAndUser

Fetch all nft trades id for a specific user (wallet). It mean, all trades (mint) made by a user.

```solidity
getTradesByNftIdAndUser(address user, uint8 nftId)
        public view returns (uint256[] memory)
```

## getTradeByTradeId

Fetch a trade info by a trade id, ie: use `getTradesByNftIdAndUser` to fetch all trades and the use getTradeByTradeId to get trade info. 

```solidity
getTradeByTradeId(uint256 tradeId)
public view returns (NftTradeInfo memory)
```
---

# Marketplaces
# Vlad VNFT Primary Marktplace

## mint

*Allow user to mint a nft and pay fees to authors, governance and dev.*

```solidity
mint(uint8 _nftId) external nonReentrant
```

## burn

*Allow user to burn a nft and get some token (money) back.*

```solidity
burn(uint256 tradeId) external nonReentrant
```

# Vlad VNFT Secondary Marktplace

## setNftSellable

*Manage if a nft can be selleable in the secondary market, it means that user can sell a minted nft.*

Options are:

- **_allowSell**: if true, allow this nft to be selleable in the secondary market.
- **_sellMinPrice**: manager can set minimum price that this nft can be sold.

```solidity
setNftSellable(uint8 _nftId, bool _allowSell,
uint256 _sellMinPrice)
external
mintingManagers
```

## sell

*Allow a user to put a minted nft to seel by a specific price (if allowed)*

Options are:
- **_tokenId**: the unique internal token id generated of this nft mint.
- **_price**: the price that this nft can be sold.

```solidity
sell(uint8 _tokenId, uint256 _price)
    external nonReentrant
```

## buy

*Allow user to buy a nft that another use put to sell in the secondary market.*

Options are:
- **_tokenId**: the unique internal token id generated of this nft mint.

```solidity
buy(uint8 _tokenId)
    external nonReentrant
```

## getSellsByNftId

```solidity
getSellsByNftId(uint8 _nftId)
    public view returns (NftTradeInfo memory TRADE[])
```

# Vlad VNFT Tertiary Marktplace

*This is the auction market, not implemented yet.*

# Vlad VNFT Transer

## transfer

```solidity
transfer(uint256 tradeId, address to) external nonReentrant
```
