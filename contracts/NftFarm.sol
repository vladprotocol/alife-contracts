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

    uint8[] public minted;
    mapping(uint8 => address[] ) public ownersOf;
    mapping(uint8 => address ) public lastOwners;

    // can manage price and limits
    mapping(address => bool) public mintingManager;

    // burn ALIFE
    address BURN_ALIFE = address(0x000000000000000000000000000000000000dEaD);

    // fee & payment management
    uint256 public FEE_ARTIST     = 3000; // 30%
    uint256 public FEE_GOVERNANCE = 1500; // 15%
    uint256 public FEE_TREASURE   = 500;  //  5%

    struct NftTradeInfo{
        uint8 nftId;
        address owner;
        uint256 price;
        uint256 artistFee;
        uint256 governanceFee;
        uint256 treasureFee;
        uint256 reserve;
        uint256 mintedIn;
        uint256 burnedIn;
    }
    mapping(uint256 => NftTradeInfo) public nftTrade;


    // artist management
    address artistFundAddr;
    address governanceFundAddr;
    address treasureFundAddr;
    struct NftInfo{
        uint8 nftId;
        address author; // nft artist/owner, who get paid
        bool allowMng; // allow owner to manage this nft
        uint256 price; // default price
        uint256 multiplier; // factor, to enable price curve
        uint256 maxMint; // max amount of nft to be minted
        uint256 minted; // amount minted
        uint256 burned; // amount burned
        uint256 lastMint; // timestamp of last minted
        uint256 startBlock; // only allow mint after this block
        uint256 endBlock; // only allow mint before this block
        address lastOwner;
        string rarity;
        string uri;
    }
    mapping(uint8 => NftInfo) public nftInfo;

    // events
    event NftAdded(uint8 indexed nftId, address indexed author, unit256 price, uint256 multiplier,
        uint256 startBlock, uint256 endBlock);
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

    function getOwnersOf( uint8 _nftId ) external view returns (address[] memory){
        return ownersOf[_nftId];
    }
    function getClaimedAmount( uint8 _nftId ) external view returns (uint256){
        return hasClaimed[_nftId];
    }

    function getMinted( address _user ) external view returns
    (uint8[] memory, uint256[] memory, address[] memory, uint256[] memory, uint256[] memory, uint256[] memory){
        uint256 total = minted.length;
        uint256[] memory mintedAmounts = new uint256[](total);
        address[] memory lastOwner = new address[](total);
        uint256[] memory myMints = new uint256[](total);

        for (uint256 index = 0; index < total; ++index) {
            uint8 nftId = minted[index];
            lastOwner[index] = lastOwners[nftId];
            mintedAmounts[index] = hasClaimed[nftId];
            myMints[index] = getMintsOf(_user, nftId);
        }

        uint256[] memory maxMintByNft = new uint256[](max_index);
        uint256[] memory prices = new uint256[](max_index);
        for (uint8 index = 0; index < max_index; ++index) {
            maxMintByNft[index] = getMaxMint(index);
            prices[index] = getPrice(index, index);
        }
        return (minted, mintedAmounts, lastOwner, maxMintByNft, prices, myMints);
    }
    function getMintsOf( address user, uint8 _nftId ) public view returns (uint256) {
        address[] storage _ownersOf = ownersOf[_nftId];
        uint256 total = _ownersOf.length;
        uint256 mints = 0;
        for (uint256 index = 0; index < total; ++index) {
            if( _ownersOf[index] == user ){
                mints = mints.add(1);
            }
        }
        return mints;
    }
    function getPrice( uint8 _nftId, uint256 _minted ) public view returns (uint256){

        NftInfo storage NFT = nftInfo[_nftId];

        // default: return the global price
        uint256 price = NFT.price;

        if( _minted == 0 ){
            return price;
        }
        if( NFT.multiplier > 0 ){
            // price curve by m-dot :)
            for( uint256 i = 0; i < _minted ; ++i ){
                price = price.mul( NFT.multiplier ).div(1000000);
            }
            return price;
        }
        return price;
    }

    function mintNFT(uint8 _nftId) external nonReentrant{

        NftInfo storage NFT = nftInfo[_nftId];

        require(NFT.nftId > 0, "NFT not available");
        require(NFT.startBlock == 0 || block.number > NFT.startBlock, "Too early");
        require(NFT.endBlock == 0 || block.number < NFT.endBlock, "Too late");

        if( NFT.minted == 0 ){
            minted.push(_nftId);
            nft.setNftName(_nftId, NFT.rarity);
        }

        NFT.minted = NFT.minted.add(1);
        NFT.lastOwner = msg.sender;
        NFT.lastMint = block.timestamp;

        require( NFT.maxMint==0 || NFT.minted <= NFT.maxMint, "Max minting reached");

        address[] storage _ownersOf = ownersOf[_nftId];
        _ownersOf.push( msg.sender );

        uint256 tokenId = nft.mint(address(msg.sender), NFT.uri, _nftId);
        NftTradeInfo storage TRADE = nftTrade[tokenId];
        TRADE.nftId = _nftId;
        TRADE.owner = msg.sender;
        NFT.price = getPrice(_nftId, NFT.minted );

        NftTradeInfo storage trade = nftTrade[tokenId];
        trade.nftId = _nftId;
        trade.tokenId = tokenId;
        trade.mintedIn = block.timestamp;
        trade.price = NFT.price;
        trade.artistFee = NFT.price.mul(FEE_ARTIST).div(10000);
        trade.governanceFee = NFT.price.mul(FEE_GOVERNANCE).div(10000);
        trade.treasureFee = NFT.price.mul(FEE_TREASURE).div(10000);
        trade.reserve = trade.price.sub(trade.artistFee).sub(trade.governanceFee).sub(trade.treasureFee);

        token.safeTransferFrom(address(msg.sender), NFT.author, trade.artistFee);
        token.safeTransferFrom(address(msg.sender), governanceFundAddr, trade.governanceFee);
        token.safeTransferFrom(address(msg.sender), treasureFundAddr, trade.treasureFee);
        token.safeTransferFrom(address(msg.sender), address(this), trade.reserve);

        emit NftMint(msg.sender, tokenId, _nftId, NFT.minted, NFT.price );
    }

    function burnNFT(uint8 tokenId) external nonReentrant{

        NftTradeInfo storage trade = nftTrade[tokenId];
        require( trade.owner == msg.sender, "not nft owner" );
        require( trade.reserve > 0 , "invalid reserve amount");
        uint256 _nftId = token.getNftId(tokenId);
        nft.burn(tokenId);
        require( trade.burnedIn != 0, "already burned");
        trade.burnedIn = block.timestamp;
        token.safeTransfer(address(msg.sender), trade.reserve);

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

    // set the price mul for a specific nft
    function adminSetPriceMultiplierByNftId(uint8 _nftId, uint256 _mul) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.multiplier = _mul;
    }

    // set the price for a specific nft
    function adminSetPriceByNftId(uint8 _nftId, uint256 _price) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.price = _price;
    }

    // set the max minting for a specific nft
    function adminSetMaxMintByNftId(uint8 _nftId, uint256 _maxAllowed) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.maxMint = _maxAllowed;
    }

    function adminSetAuthorByNftId(uint8 _nftId, address _author) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.author = _author;
    }

    function adminSetSelManagementByNftId(uint8 _nftId, bool _allowMng) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.allowMng = _allowMng;
    }

    function adminSetIntervalByNftId(uint8 _nftId, uint256 _startBlock, uint256 _blockBlock) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.startBlock = _startBlock;
        NFT.blockBlock = _blockBlock;
    }

    function adminSetUriByNftId(uint8 _nftId, string memory _uri) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.uri = _uri;
    }

    function adminSetRarityByNftId(uint8 _nftId, string memory _rarity) external management(nftInfo[_nftId]) {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.rarity = _rarity;
    }

    // manage the minting interval to avoid front-run exploiters
    function addNft(uint8 _nftId, address _author, unit256 _price, uint256 _multiplier,
        uint256 _startBlock, uint256 _blockBlock, bool _allowMng,
        string memory _rarity, string memory _uri) external mintingManagers {
        NftInfo storage NFT = nftInfo[_nftId];
        NFT.nftId = _nftId;
        NFT.author = _author;
        NFT.price = _price;
        NFT.maxMint = _maxMint;
        NFT.multiplier = _multiplier;
        NFT.startBlock = _startBlock;
        NFT.blockBlock = _blockBlock;
        NFT.allowMng = _allowMng; // allow owner to manage this nft
        NFT.rarity = _rarity;
        NFT.uri = string(abi.encodePacked(_uri, "/", itod(_nftId), ".json"));
        emit NftAdded(_nftId, _author, _price, _multiplier);
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

    modifier management( NftInfo storage NFT ){
        require(mintingManager[msg.sender] == true || (NFT.allowMng==true && NFT.author == msg.sender), "not owner|manager");
        _;
    }
    modifier mintingManagers(){
        require(mintingManager[_msgSender()] == true, "Managers: not a manager");
        _;
    }
}
