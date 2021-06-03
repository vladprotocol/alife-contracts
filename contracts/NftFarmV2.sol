// SPDX-License-Identifier: MIT
/**
Copyright 2021 <bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

// 2020 - PancakeSwap Team - https://pancakeswap.com
// 2021 - bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep

**/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./libs/INFT.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

contract NftFarmV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    INFT public nft;    // default platform nft
    IBEP20 public token;// default platform payment token

    // global stats
    uint256 totalMint; // total of all mints
    uint256 totalBurn; // total of all burns
    uint256 totalTokensCollected; //amount of tokens received
    uint256 totalTokensRefunded; //amount of tokens refunded to users on burn
    uint256 totalPaidToAuthors; //amount of tokens sent to nft authors

    uint8[] public minted; // array of nft minted, unique, added on first mint only.
    mapping(uint8 => address[]) public ownersOf; // wallets by nftId

    // can manage price and limits
    mapping(address => bool) public mintingManager;

    // fee & payment management
    struct PlatformFees {
        uint256 authorFee; // 30%
        uint256 govFee; // 15%
        uint256 devFee;  //  5%

        uint256 marketAuthorFee; // 30%
        uint256 marketGovFee; // 15%
        uint256 marketDevFee;  //  5%
    }

    PlatformFees platformFees;

    // artist management
    struct PlatformAddresses {
        address govFeeAddr;
        address devFeeAddr;
    }

    PlatformAddresses platformAddresses;

    struct NftInfo {
        uint8 nftId;
        address author; // nft artist/owner, who get paid
        uint256 authorFee; // fee to pay to author of this nft
        bool allowMng; // allow owner to manage this nft
        uint256 authorId; // unique id for this author
        string authorName; // author name (string)
        string authorTwitter; // author twitter account ie (@test)
        string rarity;
        string uri;
        uint256 startBlock; // only allow mint after this block
        uint256 endBlock;   // only allow mint before this block
        uint256 status;     // use to: 0=inactive, 1=active, 2=auction
    }

    struct NftInfoState {
        uint8 nftId;
        uint256 price;      // default price
        uint256 maxMint;    // max amount of nft to be minted
        uint256 multiplier; // factor, to enable price curve
        uint256 rarityId;   // unique id for this rarity
        uint256 minted;     // amount minted
        uint256 lastMint;   // timestamp of last minted
        uint256 burned;     // amount burned
        uint256 lastBurn;   // timestamp of last burn
        address lastOwner;  // last one that minted this nft
        INFT nft;          // mint/burn this nft
        IBEP20 token;      // buy/sell using this token (AfterLife, WBNB, BUSD)
    }

    // array of all nft added
    uint256[] public nftIndex;
    // basic nft info to display
    mapping(uint8 => NftInfo) public nftInfo;
    // state info, like minting, minted, burned
    mapping(uint8 => NftInfoState) public nftInfoState;
    // list of all nft minting by nft id
    mapping(uint8 => uint256[]) public listOfTradesByTokenId;

    // primary trade info
    struct NftTradeInfo {
        uint8 nftId;
        uint256 tokenId;
        address owner;
        uint256 price;
        uint256 artistFee;
        uint256 governanceFee;
        uint256 devFee;
        uint256 reserve;
        uint256 mintedIn;
        uint256 burnedIn;
        uint256 sellPrice;
    }

    mapping(uint256 => NftTradeInfo) public nftTrade;

    struct NftSecondaryMarket {
        uint8 nftId;
        bool allowSell;   // allow owner to sell this nft
        uint256 sellMinPrice; // min price allowed to sell
    }

    mapping(uint8 => NftSecondaryMarket) public nftSecondaryMarket;

    // secondary trade info
    struct NftSecondaryTradeInfo {
        uint8 nftId;
        uint256 tokenId;
        address owner;
        uint256 price;
        uint256 artistFee;
        uint256 governanceFee;
        uint256 devFee;
        uint256 totalSold;
        uint256 sellPrice;
        uint256 soldFor;
        uint256 soldIn;
    }

    mapping(uint256 => NftSecondaryTradeInfo) public nftSecondaryTradeInfo;


    // filters
    mapping(string => uint8[]) public listOfNftByRarity;
    mapping(string => uint8[]) public listOfNftByAuthor;

    mapping(string => uint256) public authorIdByName;
    mapping(string => uint256) public rarityIdByName;
    string[] public listOfAuthors;
    string[] public listOfRarity;

    // events
    event NftAdded(uint8 indexed nftId, address indexed author, uint256 startBlock, uint256 endBlock);
    event NftChanged(uint8 indexed nftId, address indexed author, uint256 startBlock, uint256 endBlock);
    event NftStateAdded(uint8 indexed nftId, uint256 price, uint256 multiplier);

    event NftMint(address indexed to, uint256 indexed tokenId, uint8 indexed nftId, uint256 amount, uint256 price);
    event NftBurn(address indexed from, uint256 indexed tokenId);

    constructor(INFT _nft, IBEP20 _token) public {
        nft = _nft;
        token = _token;
        mintingManager[msg.sender] = true;

        // all fee wallets defaults to deployer, must be changed later.
        platformAddresses.govFeeAddr = msg.sender;
        platformAddresses.devFeeAddr = msg.sender;

        platformFees.authorFee = 3000;
        // 30%
        platformFees.govFee = 1500;
        // 15%
        platformFees.devFee = 500;
        //  5%

        platformFees.marketAuthorFee = 3000;
        // 30%
        platformFees.marketGovFee = 1500;
        // 15%
        platformFees.marketDevFee = 500;
        //  5%

    }

    function getOwnersOf(uint8 _nftId) external view returns (address[] memory){
        return ownersOf[_nftId];
    }


    function getMinted(address _user) external view returns
    (uint8[] memory, uint256[] memory, address[] memory, uint256[] memory, uint256[] memory, uint256[] memory){
        uint256 total = minted.length;
        uint256[] memory mintedAmounts = new uint256[](total);
        address[] memory lastOwner = new address[](total);
        uint256[] memory myMints = new uint256[](total);

        for (uint256 index = 0; index < total; ++index) {
            uint8 nftId = minted[index];
            NftInfoState storage NFT = nftInfoState[nftId];
            lastOwner[index] = NFT.lastOwner;
            mintedAmounts[index] = NFT.minted;
            myMints[index] = getMintsOf(_user, nftId);
        }

        uint256 nftTotal = nftIndex.length;
        uint256[] memory maxMintByNft = new uint256[](nftTotal);
        uint256[] memory prices = new uint256[](nftTotal);
        for (uint8 nftId = 0; nftId < nftTotal; ++nftId) {
            NftInfoState storage NFT = nftInfoState[nftId];
            maxMintByNft[nftId] = NFT.maxMint;
            prices[nftId] = getPrice(nftId, NFT.minted);
        }

        return (minted, mintedAmounts, lastOwner, maxMintByNft, prices, myMints);
    }


    function getMintsOf(address user, uint8 _nftId) public view returns (uint256) {
        address[] storage _ownersOf = ownersOf[_nftId];
        uint256 total = _ownersOf.length;
        uint256 mints = 0;
        for (uint256 index = 0; index < total; ++index) {
            if (_ownersOf[index] == user) {
                mints = mints.add(1);
            }
        }
        return mints;
    }

    function getPrice(uint8 _nftId, uint256 _minted) public view returns (uint256){

        NftInfoState storage NFT = nftInfoState[_nftId];

        uint256 price = NFT.price;

        if (_minted == 0) {
            return price;
        }
        if (NFT.multiplier > 0) {
            // price curve by m-dot :)
            for (uint256 i = 0; i < _minted; ++i) {
                price = price.mul(NFT.multiplier).div(1000000);
            }
            return price;
        }
        return price;
    }


    function mint(uint8 _nftId) external nonReentrant {

        NftInfo storage NFT = nftInfo[_nftId];
        NftInfoState storage NftState = nftInfoState[_nftId];

        require(NftState.nftId > 0, "NFT not available");
        require(NFT.status > 0, "nft disabled");
        require(NFT.startBlock == 0 || block.number > NFT.startBlock, "Too early");
        require(NFT.endBlock == 0 || block.number < NFT.endBlock, "Too late");

        if (NftState.minted == 0) {
            minted.push(_nftId);
            NftState.nft.setNftName(_nftId, NFT.rarity);
        }

        NftState.minted = NftState.minted.add(1);
        NftState.lastOwner = msg.sender;
        NftState.lastMint = block.timestamp;
        NftState.price = getPrice(_nftId, NftState.minted);

        require(NftState.maxMint == 0 || NftState.minted <= NftState.maxMint, "Max minting reached");

        address[] storage _ownersOf = ownersOf[_nftId];
        _ownersOf.push(msg.sender);

        uint256 tokenId = NftState.nft.mint(address(msg.sender), NFT.uri, _nftId);

        uint256[] storage tradesByTokenId = listOfTradesByTokenId[_nftId];
        tradesByTokenId.push(tokenId);

        NftTradeInfo storage TRADE = nftTrade[tokenId];
        TRADE.nftId = _nftId;
        TRADE.owner = msg.sender;
        TRADE.nftId = _nftId;
        TRADE.tokenId = tokenId;

        TRADE.mintedIn = block.timestamp;
        TRADE.price = NftState.price;
        if (NFT.authorFee == 0) {
            TRADE.artistFee = TRADE.price.mul(platformFees.authorFee).div(10000);
        } else {
            TRADE.artistFee = TRADE.price.mul(NFT.authorFee).div(10000);
        }
        TRADE.governanceFee = TRADE.price.mul(platformFees.govFee).div(10000);
        TRADE.devFee = TRADE.price.mul(platformFees.devFee).div(10000);
        TRADE.reserve = TRADE.price.sub(TRADE.artistFee).sub(TRADE.governanceFee).sub(TRADE.devFee);

        NftState.token.safeTransferFrom(address(msg.sender), NFT.author, TRADE.artistFee);
        NftState.token.safeTransferFrom(address(msg.sender), platformAddresses.govFeeAddr, TRADE.governanceFee);
        NftState.token.safeTransferFrom(address(msg.sender), platformAddresses.devFeeAddr, TRADE.devFee);
        NftState.token.safeTransferFrom(address(msg.sender), address(this), TRADE.reserve);

        totalMint = totalMint.add(1);
        totalTokensCollected = totalTokensCollected.add(NftState.price);
        totalPaidToAuthors = totalPaidToAuthors.add(TRADE.artistFee);
        emit NftMint(msg.sender, tokenId, _nftId, NftState.minted, NftState.price);

    }

    function burn(uint256 tokenId) external nonReentrant {

        NftTradeInfo storage TRADE = nftTrade[tokenId];
        NftInfoState storage NftState = nftInfoState[TRADE.nftId];
        NftInfo storage NFT = nftInfo[TRADE.nftId];

        require(TRADE.owner == msg.sender, "not nft owner");
        require(TRADE.reserve > 0, "invalid reserve amount");
        require(TRADE.burnedIn != 0, "already burned");
        require(NftState.minted > 0, "no burn available");
        require(NFT.status > 0, "nft disabled");

        NftState.nft.burn(tokenId);
        TRADE.burnedIn = block.timestamp;

        NftState.burned = NftState.burned.add(1);
        NftState.lastBurn = block.timestamp;
        NftState.minted = NftState.minted.sub(1);

        NftState.token.safeTransfer(address(msg.sender), TRADE.reserve);
        totalBurn = totalBurn.add(1);
        totalTokensRefunded = totalTokensRefunded.add(TRADE.reserve);

        emit NftBurn(msg.sender, tokenId);
    }

    function itod(uint256 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            while (x > 0) {
                str = string(abi.encodePacked(uint8(x % 10 + 48), str));
                x /= 10;
            }
            return str;
        }
        return "0";
    }


    // manage the minting interval to avoid front-run exploiters
    function add(uint8 _nftId, address _author,
        uint256 _startBlock, uint256 _endBlock, bool _allowMng,
        string memory _rarity, string memory _uri, uint256 _authorFee,
        string memory _authorName, string memory _authorTwitter, uint256 _status)
    external
    mintingManagers
    {

        NftInfo storage NFT = nftInfo[_nftId];
        NftInfoState storage NftState = nftInfoState[_nftId];

        require(NFT.nftId == 0, "NFT already exists");

        nftIndex.push(_nftId);

        NFT.nftId = _nftId;
        NFT.author = _author;
        NFT.authorFee = _authorFee;
        NFT.allowMng = _allowMng;
        NFT.authorName = _authorName;
        NFT.authorTwitter = _authorTwitter;
        NFT.rarity = _rarity;
        NFT.uri = string(abi.encodePacked(_uri, "/", itod(_nftId), ".json"));
        NFT.startBlock = _startBlock;
        NFT.endBlock = _endBlock;
        NFT.status = _status;

        NftState.nftId = _nftId;
        NftState.nft = nft; // default platform nft
        NftState.token = token; // default platform payment token

        require(platformFees.authorFee.add(platformFees.govFee).add(platformFees.devFee).add(_authorFee) < 10000, "FEE TOO HIGH");

        uint8[] storage nftByRarity = listOfNftByRarity[_rarity];
        uint8[] storage nftByAuthors = listOfNftByAuthor[_authorName];

        if (nftByRarity.length == 0) {
            listOfRarity.push(_rarity);
            rarityIdByName[_rarity] = listOfRarity.length;
        }
        if (nftByAuthors.length == 0) {
            listOfAuthors.push(_authorName);
            authorIdByName[_authorName] = listOfAuthors.length;
        }

        NFT.authorId = authorIdByName[_authorName];
        NftState.rarityId = rarityIdByName[_rarity];

        nftByRarity.push(_nftId);
        nftByAuthors.push(_nftId);

        emit NftAdded(_nftId, _author, _startBlock, _endBlock);
    }

    function set(uint8 _nftId, address _author,
        uint256 _startBlock, uint256 _endBlock, bool _allowMng,
        string memory _rarity, string memory _uri, uint256 _authorFee,
        string memory _authorName, string memory _authorTwitter)
    external
    mintingManagers
    {

        NftInfo storage NFT = nftInfo[_nftId];

        require(NFT.nftId != 0, "NFT does not exists");

        NFT.author = _author;
        NFT.authorFee = _authorFee;
        NFT.allowMng = _allowMng;
        NFT.authorName = _authorName;
        NFT.authorTwitter = _authorTwitter;
        NFT.rarity = _rarity;
        NFT.uri = string(abi.encodePacked(_uri, "/", itod(_nftId), ".json"));
        NFT.startBlock = _startBlock;
        NFT.endBlock = _endBlock;

        require(platformFees.authorFee.add(platformFees.govFee).add(platformFees.devFee).add(_authorFee) < 10000, "FEE TOO HIGH");

        emit NftChanged(_nftId, _author, _startBlock, _endBlock);
    }

    // manage the minting interval to avoid front-run exploiters
    function setState(uint8 _nftId, uint256 _price,
        uint256 _maxMint, uint256 _multiplier)
    external
    mintingManagers
    {
        NftInfoState storage NftState = nftInfoState[_nftId];
        require(NftState.nftId != 0, "NFT does not exists");
        NftState.price = _price;
        NftState.maxMint = _maxMint;
        NftState.multiplier = _multiplier;
        emit NftStateAdded(_nftId, _price, _multiplier);
    }
    function adminSetNftTokenMarket(uint8 nftId, INFT _nft, IBEP20 _token) external mintingManagers {
        NftInfoState storage INFO = nftInfoState[nftId];
        INFO.nft = _nft;
        INFO.token = _token;
    }

    // change governance address
    function adminSetgovFeeAddr(address _newAddr) external onlyOwner {
        platformAddresses.govFeeAddr = _newAddr;
    }
    // change treasure/dev address
    function adminSetdevFeeAddr(address _newAddr) external onlyOwner {
        platformAddresses.devFeeAddr = _newAddr;
    }

    // manage nft emission
    function adminSetMintingManager(address _manager, bool _status) external onlyOwner {
        mintingManager[_manager] = _status;
    }

    function adminSetPlatformFee(uint256 govFee, uint256 devFee, uint256 authorFee) external onlyOwner {
        platformFees.authorFee = govFee;
        platformFees.govFee = devFee;
        platformFees.devFee = authorFee;
        require(authorFee.add(govFee).add(devFee).add(platformFees.authorFee) < 10000, "FEE TOO HIGH");
    }

    function adminSetMarketFee(uint256 govFee, uint256 devFee, uint256 authorFee) external onlyOwner {
        platformFees.marketAuthorFee = govFee;
        platformFees.marketGovFee = devFee;
        platformFees.marketDevFee = authorFee;
        require(authorFee.add(govFee).add(devFee).add(platformFees.authorFee) < 10000, "FEE TOO HIGH");
    }


    modifier management(NftInfo storage NFT){
        require(mintingManager[msg.sender] == true || (NFT.allowMng == true && NFT.author == msg.sender), "not owner|manager");
        _;
    }

    modifier mintingManagers(){
        require(mintingManager[_msgSender()] == true, "Managers: not a manager");
        _;
    }

    function getNftByAuthor(string memory author) public view returns
    (NftInfo[] memory info, NftInfoState[] memory state)
    {
        uint256 authorId = authorIdByName[author];
        uint8[] memory list = listOfNftByAuthor[author];
        uint256 total = list.length;
        uint256 pos = 0;
        for (uint8 index = 0; index < total; ++index) {
            NftInfo memory _info = nftInfo[index];
            if (_info.authorId != authorId) {
                continue;
            }
            NftInfoState memory _state = nftInfoState[index];
            info[pos] = _info;
            state[pos] = _state;
            pos = pos.add(1);
        }
        return (info, state);
    }

    function getNftByRarity(string memory rarity) public view returns
    (NftInfo[] memory, NftInfoState[] memory)
    {
        uint8[] memory list = listOfNftByRarity[rarity];
        uint256 total = list.length;
        NftInfo[] memory info = new NftInfo[](total);
        NftInfoState[] memory state = new NftInfoState[](total);

        uint256 rarityId = rarityIdByName[rarity];

        uint256 pos = 0;
        for (uint8 index = 0; index < total; ++index) {
            uint8 nftId = list[index];
            NftInfoState memory _state = nftInfoState[nftId];
            if (_state.rarityId != rarityId) {
                continue;
            }
            NftInfo memory _info = nftInfo[nftId];
            info[pos] = _info;
            state[pos] = _state;
            pos = pos.add(1);
        }
        return (info, state);
    }

    // use to transfer your nft to someone (to gif for example)
    function transfer(uint256 tokenId, address to) external nonReentrant {
        NftTradeInfo storage TRADE = nftTrade[tokenId];
        require( TRADE.tokenId != 0, "nft not found");
        require( TRADE.owner == msg.sender, "nft owner");
        NftInfoState storage NftState = nftInfoState[TRADE.nftId];
        NftState.nft.safeTransferFrom(msg.sender, to, tokenId);
    }

    // nft secondary market sub-system:
    function setSell(uint8 _nftId, bool _allowSell,
        uint256 _sellMinPrice)
    external
    mintingManagers
    {
        NftSecondaryMarket storage NFT = nftSecondaryMarket[_nftId];
        require(NFT.nftId != 0, "NFT does not exists");
        NFT.allowSell = _allowSell;
        NFT.sellMinPrice = _sellMinPrice;
    }

    function sell(uint8 _tokenId, uint256 _price)
    external nonReentrant
    {
        NftTradeInfo storage TRADE = nftTrade[_tokenId];
        uint8 _nftId = TRADE.nftId;
        NftSecondaryMarket storage MARKET = nftSecondaryMarket[_nftId];

        require(_tokenId != 0, "NFT not minted");
        require(TRADE.owner != msg.sender, "not owner");
        require(MARKET.allowSell != false, "NFT not sellable");
        require(_price > 0, "invalid price");
        require(_price >= MARKET.sellMinPrice, "price bellow min price");
        TRADE.sellPrice = _price;
    }

    function buy(uint8 _tokenId)
    external nonReentrant
    {
        NftTradeInfo storage TRADE = nftTrade[_tokenId];
        NftSecondaryMarket storage MARKET = nftSecondaryMarket[TRADE.nftId];
        // NftInfo storage NFT = nftInfo[TRADE.nftId];
        NftInfoState storage NftState = nftInfoState[TRADE.nftId];


        require(_tokenId != 0, "NFT not minted");
        require(MARKET.allowSell != false, "NFT not sellable");
        require(TRADE.price > 0, "invalid price");
        require(TRADE.price >= MARKET.sellMinPrice, "price bellow min price");

        buyDoPayment(_tokenId);

        NftState.lastOwner = msg.sender; // new owner
        TRADE.sellPrice = 0; // reset selling property
        TRADE.owner = msg.sender; // transfer to new owner

    }

    function buyDoPayment(uint8 _tokenId) internal {
        NftTradeInfo storage TRADE = nftTrade[_tokenId];
        NftInfo storage NFT = nftInfo[TRADE.nftId];
        NftInfoState storage STATE = nftInfoState[TRADE.nftId];

        // transfer tokens from new olwer to old owner
        uint256 _authorFee = NFT.authorFee;
        if (_authorFee == 0) {
            _authorFee = platformFees.authorFee;
            // default author fee
        }

        uint256 _artistFee = TRADE.price.mul(_authorFee).div(10000);
        uint256 _governanceFee = TRADE.price.mul(platformFees.govFee).div(10000);
        uint256 _devFee = TRADE.price.mul(platformFees.devFee).div(10000);
        uint256 _totalSold = TRADE.price.sub(_artistFee).sub(_governanceFee).sub(_devFee);

        // do platform transfers
        STATE.token.safeTransferFrom(address(msg.sender), NFT.author, _artistFee);
        STATE.token.safeTransferFrom(address(msg.sender), platformAddresses.govFeeAddr, _governanceFee);
        STATE.token.safeTransferFrom(address(msg.sender), platformAddresses.devFeeAddr, _devFee);

        // after fees, pay old owner:
        STATE.token.safeTransferFrom(address(msg.sender), TRADE.owner, _totalSold);

        NftSecondaryTradeInfo storage secondaryTrade = nftSecondaryTradeInfo[TRADE.nftId];
        // accumulate fees paid
        secondaryTrade.artistFee = secondaryTrade.artistFee.add(_artistFee);
        secondaryTrade.governanceFee = secondaryTrade.governanceFee.add(_governanceFee);
        secondaryTrade.devFee = secondaryTrade.devFee.add(_devFee);
        secondaryTrade.totalSold = secondaryTrade.totalSold.add(_totalSold);
        secondaryTrade.soldFor = TRADE.price; // price sold
        secondaryTrade.soldIn = block.timestamp; //when sold

        // transfer from old owner to hew owner
        STATE.nft.safeTransferFrom(TRADE.owner, msg.sender, _tokenId);

    }


}
