// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./NFT.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

pragma solidity ^0.6.12;

contract NftFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    NFT public nft;
    IBEP20 public token;

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

    // burn ALIFE
    address BURN_ALIFE = address(0x000000000000000000000000000000000000dEaD);

    // fee & payment management
    uint256 public authorFee = 3000; // 30%
    uint256 public govFee = 1500; // 15%
    uint256 public devFee = 500;  //  5%

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
    }

    mapping(uint256 => NftTradeInfo) public nftTrade;


    // artist management
    address artistFundAddr;
    address governanceFundAddr;
    address treasureFundAddr;

    struct NftInfo {
        uint8 nftId;
        address author; // nft artist/owner, who get paid
        uint256 authorFee; // fee to pay to author of this nft
        bool allowMng; // allow owner to manage this nft
        string authorName;
        string authorTwitter;
        string rarity;
        string uri;
        uint256 startBlock; // only allow mint after this block
        uint256 endBlock; // only allow mint before this block
    }

    struct NftInfoState {
        uint8 nftId;
        uint256 price; // default price
        uint256 maxMint; // max amount of nft to be minted
        uint256 multiplier; // factor, to enable price curve

        uint256 minted; // amount minted
        uint256 lastMint; // timestamp of last minted
        uint256 burned; // amount burned
        uint256 lastBurn; // timestamp of last burn
        address lastOwner;
    }

    // array of all nft added
    uint256[] public nftIndex;
    // basic nft info to display
    mapping(uint8 => NftInfo) public nftInfo;
    // state info, like minting, minted, burned
    mapping(uint8 => NftInfoState) public nftInfoState;
    // list of all nft minting by nft id
    mapping(uint8 => uint256[]) public listOfTradesByTokenId;

    // events
    event NftAdded(uint8 indexed nftId, address indexed author, uint256 startBlock, uint256 endBlock);
    event NftChanged(uint8 indexed nftId, address indexed author, uint256 startBlock, uint256 endBlock);
    event NftStateAdded(uint8 indexed nftId, uint256 price, uint256 multiplier);

    event NftMint(address indexed to, uint256 indexed tokenId, uint8 indexed nftId, uint256 amount, uint256 price);
    event NftBurn(address indexed from, uint256 indexed tokenId);

    constructor(NFT _nft, IBEP20 _token) public {
        nft = _nft;
        token = _token;
        mintingManager[msg.sender] = true;

        // all fee wallets defaults to deployer, must be changed later.
        artistFundAddr = msg.sender;
        governanceFundAddr = msg.sender;
        treasureFundAddr = msg.sender;

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
        require(NFT.startBlock == 0 || block.number > NFT.startBlock, "Too early");
        require(NFT.endBlock == 0 || block.number < NFT.endBlock, "Too late");

        if (NftState.minted == 0) {
            minted.push(_nftId);
            nft.setNftName(_nftId, NFT.rarity);
        }

        NftState.minted = NftState.minted.add(1);
        NftState.lastOwner = msg.sender;
        NftState.lastMint = block.timestamp;
        NftState.price = getPrice(_nftId, NftState.minted);

        require(NftState.maxMint == 0 || NftState.minted <= NftState.maxMint, "Max minting reached");

        address[] storage _ownersOf = ownersOf[_nftId];
        _ownersOf.push(msg.sender);

        uint256 tokenId = nft.mint(address(msg.sender), NFT.uri, _nftId);

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
            TRADE.artistFee = TRADE.price.mul(authorFee).div(10000);
        } else {
            TRADE.artistFee = TRADE.price.mul(NFT.authorFee).div(10000);
        }
        TRADE.governanceFee = TRADE.price.mul(govFee).div(10000);
        TRADE.devFee = TRADE.price.mul(devFee).div(10000);
        TRADE.reserve = TRADE.price.sub(TRADE.artistFee).sub(TRADE.governanceFee).sub(TRADE.devFee);

        token.safeTransferFrom(address(msg.sender), NFT.author, TRADE.artistFee);
        token.safeTransferFrom(address(msg.sender), governanceFundAddr, TRADE.governanceFee);
        token.safeTransferFrom(address(msg.sender), treasureFundAddr, TRADE.devFee);
        token.safeTransferFrom(address(msg.sender), address(this), TRADE.reserve);

        totalMint = totalMint.add(1);
        totalTokensCollected = totalTokensCollected.add(NftState.price);
        totalPaidToAuthors = totalPaidToAuthors.add(TRADE.artistFee);
        emit NftMint(msg.sender, tokenId, _nftId, NftState.minted, NftState.price);

    }

    function burn(uint256 tokenId) external nonReentrant {

        NftTradeInfo storage TRADE = nftTrade[tokenId];

        require(TRADE.owner == msg.sender, "not nft owner");
        require(TRADE.reserve > 0, "invalid reserve amount");
        require(TRADE.burnedIn != 0, "already burned");

        uint8 _nftId = nft.getNftId(tokenId);
        nft.burn(tokenId);

        TRADE.burnedIn = block.timestamp;

        NftInfoState storage NftState = nftInfoState[_nftId];
        NftState.burned = NftState.burned.add(1);
        NftState.lastBurn = block.timestamp;

        token.safeTransfer(address(msg.sender), TRADE.reserve);
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
    function addNft(uint8 _nftId, address _author,
        uint256 _startBlock, uint256 _endBlock, bool _allowMng,
        string memory _rarity, string memory _uri, uint256 _authorFee,
        string memory _authorName, string memory _authorTwitter)
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

        NftState.nftId = _nftId;

        getTotalFee(_authorFee);

        emit NftAdded(_nftId, _author, _startBlock, _endBlock);
    }

    function setNft(uint8 _nftId, address _author,
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

        getTotalFee(_authorFee);

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

    // default addr if nor artis addr set
    function adminSetArtistFundAddr(address _newAddr) external onlyOwner {
        artistFundAddr = _newAddr;
    }

    // change governance address
    function adminSetGovernanceFundAddr(address _newAddr) external onlyOwner {
        governanceFundAddr = _newAddr;
    }
    // change treasure/dev address
    function adminSetTreasureFundAddr(address _newAddr) external onlyOwner {
        treasureFundAddr = _newAddr;
    }

    // manage nft emission
    function adminSetMintingManager(address _manager, bool _status) external onlyOwner {
        mintingManager[_manager] = _status;
    }

    function adminSetDefaultArtistFee(uint256 _fee) external onlyOwner {
        getTotalFee(_fee);
        authorFee = _fee;
    }

    function adminSetDefaultGovernanceFee(uint256 _fee) external onlyOwner {
        getTotalFee(_fee);
        govFee = _fee;
    }

    function adminSetDefaultTreasureFee(uint256 _fee) external onlyOwner {
        getTotalFee(_fee);
        devFee = _fee;
    }

    function getTotalFee(uint256 fee) public view {
        require(authorFee.add(govFee).add(devFee).add(fee) < 10000, "FEE TOO HIGH");
    }

    modifier management(NftInfo storage NFT){
        require(mintingManager[msg.sender] == true || (NFT.allowMng == true && NFT.author == msg.sender), "not owner|manager");
        _;
    }

    modifier mintingManagers(){
        require(mintingManager[_msgSender()] == true, "Managers: not a manager");
        _;
    }
}
