/*
http://vlad.finance/
https://t.me/VladFinanceOfficial
https://vlad-finance.medium.com/
https://twitter.com/VladFinance
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./AfterLife.sol";
import "./NFT.sol";
import "./NftFarm.sol";
import "./libs/stringUtils.sol";

// MasterChef is the master of Life. He can make Life and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once ALIFE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChefV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using StringUtils for string;

    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. ALIFEs to distribute per block.
        uint256 lastRewardBlock;    // Last block number that ALIFEs distribution occurs.
        uint256 accLifePerShare;    // Accumulated ALIFEs per share, times 1e12. See below.
        uint16 depositFeeBP;       // Deposit fee in basis points
        uint8 mustHaveNft;          // If passed, user must have this nft cat to farm
    }

    // The ALIFE TOKEN!
    AfterLife public alife;
    NFT public nft;
    NftFarm public nftMinter1;
    NftFarm public nftMinter2;
    // Dev address.
    address public devaddr;
    // ALIFE tokens created per block.
    uint256 public tokenPerBlock;
    // Bonus muliplier for early alife makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when ALIFE mining starts.
    uint256 public startBlock;


    uint8 private constant BASIC = 1;
    uint8 private constant RARE = 2;
    uint8 private constant EPIC = 3;
    uint8 private constant LEGENDARY = 4;
    mapping( uint8 => string ) private cat_hash;
    mapping( uint8 => uint8[3] ) private categories;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);

    constructor(
        address _alife,
        address _devaddr,
        address _feeAddress,
        uint256 _tokenPerBlock,
        uint256 _startBlock
    ) public {
        alife = AfterLife(_alife);
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        nft_init();
    }
    function nft_init() internal {

        nft = NFT(0x3F7C7C24fFA2ceFfaACE11B39D5b8a575A4B0674);
        nftMinter1 = NftFarm(0x08d2cBc5EFd1B56034F4628bB32e947C0d86BbB1);
        nftMinter2 = NftFarm(0x6a63AF63675D3c9D498DF43Aa163F9243E7b4646);
        // related to nft minting farm overlap

        categories[BASIC][0] = 0;
        categories[BASIC][1] = 1;
        categories[BASIC][2] = 2;
        // basic
        categories[RARE][0] = 3;
        categories[RARE][1] = 4;
        categories[RARE][2] = 5;
        // rare
        categories[EPIC][0] = 0;
        categories[EPIC][1] = 1;
        categories[EPIC][2] = 2;
        // epic
        categories[LEGENDARY][0] = 3;
        categories[LEGENDARY][1] = 4;
        categories[LEGENDARY][2] = 5;
        // legendary
        cat_hash[BASIC] = "QmWB5xPBcFRn8qR4uu1VHt1k9vUrxvbezYv3jDC7WD29ie";
        cat_hash[RARE] = "QmWB5xPBcFRn8qR4uu1VHt1k9vUrxvbezYv3jDC7WD29ie";
        cat_hash[EPIC] = "QmX9UuF41nfhnESX3DnVHhC4XwuYAcLEReGyN4CtE8P7Bg";
        cat_hash[LEGENDARY] = "QmX9UuF41nfhnESX3DnVHhC4XwuYAcLEReGyN4CtE8P7Bg";
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate, uint8 _mustHaveNft) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accLifePerShare : 0,
        depositFeeBP : _depositFeeBP,
        mustHaveNft : _mustHaveNft
        }));
    }

    // Update the given pool's ALIFE allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending ALIFEs on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLifePerShare = pool.accLifePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 alifeReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accLifePerShare = accLifePerShare.add(alifeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accLifePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 alifeReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        alife.mint(devaddr, alifeReward.div(10));
        alife.mint(address(this), alifeReward);
        pool.accLifePerShare = pool.accLifePerShare.add(alifeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for ALIFE allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accLifePerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeLifeTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accLifePerShare).div(1e12);
        bool has_nft = mustHaveNft(msg.sender, pool.mustHaveNft);
        require(has_nft, "Must have NFT to deposit.");
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accLifePerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeLifeTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accLifePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe alife transfer function, just in case if rounding error causes pool to not have enough ALIFEs.
    function safeLifeTransfer(address _to, uint256 _amount) internal {
        uint256 alifeBal = alife.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > alifeBal) {
            transferSuccess = alife.transfer(_to, alifeBal);
        } else {
            transferSuccess = alife.transfer(_to, _amount);
        }
        require(transferSuccess, "safeLifeTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _tokenPerBlock) public onlyOwner {
        massUpdatePools();
        tokenPerBlock = _tokenPerBlock;
        emit UpdateEmissionRate(msg.sender, _tokenPerBlock);
    }

    // TODO: test case
    function set_rarity(uint256 _pid, uint8 _mustHaveNft) public onlyOwner {
        poolInfo[_pid].mustHaveNft = _mustHaveNft;
    }

    // TODO: test case
    function mustHaveNft(address sender, uint8 id) public view returns (bool) {
        if (id == 0) {
            return true;
        }
        bool nftFound1 = hasNft(nftMinter1, sender, id);
        bool nftFound2 = hasNft(nftMinter2, sender, id);
        return nftFound1 || nftFound2;
    }

    // TODO: test case
    function hasNft(NftFarm farm, address sender, uint8 id) internal view returns (bool){
        uint8[3] memory cat = categories[id]; // (0,1,2) | (3,4,5)
        for( uint i = 0 ; i < 2 ; ++i ){
            uint8 nftId = cat[i]; // 0, 2, 3
            if( farm.getMintsOf(sender, nftId) == 0 )
                continue;
            string memory uri = nft.tokenURI( nftId );
            if( uri.indexOf(cat_hash[id]) != -1 )
                return true;
        }
        return false;
    }
}
