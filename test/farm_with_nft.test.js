const web3 = require('web3');
const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, time, expectEvent, constants} = require('@openzeppelin/test-helpers');
const {expect} = require('chai');
const Token = contract.fromArtifact('AfterLife');
const MockBEP20 = contract.fromArtifact('MockBEP20');
const NFT = contract.fromArtifact('NFT');
const NftFarm = contract.fromArtifact('NftFarm');
const MasterChefV2 = contract.fromArtifact('MasterChefV2');
let _deployer, _user;

describe('MasterChefV2', function () {
    beforeEach(async function () {
        _deployer = accounts[0];
        _user = accounts[1];

        this.token = await Token.new({from: _deployer});
        this.LP = await MockBEP20.new("LP TOken","LP", {from: _deployer});

        const deposit = web3.utils.toWei('100');
        this.token.mint(_user, deposit, {from: _deployer});
        this.LP.mint(_user, deposit, {from: _deployer});

        const _devaddr = accounts[0];
        const _feeAddress = accounts[2];
        const _tokenPerBlock = web3.utils.toWei('1');

        const _startBlock = 1;
        this.pool = await MasterChefV2.new(
            this.token.address, _devaddr, _feeAddress, _tokenPerBlock, _startBlock,
            {from: _deployer});
        await this.token.transferOwnership(this.pool.address, {from: _deployer});
    });

    describe('TEST POOL', function () {
        const deposit = web3.utils.toWei('100');
        it('farm without nft', async function () {
            // add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate, uint8 _mustHaveNft)
            const pid = 0;
            const allocPoint = '0';
            const lpToken = this.LP.address;
            const depositFeeBP = '0';
            const withUpdate = true;
            const mustHaveNft = 0;
            await this.pool.add(allocPoint, lpToken, depositFeeBP, withUpdate, mustHaveNft, {from: _deployer});
            await this.LP.approve(this.pool.address, deposit, {from: _user});
            await this.pool.deposit(pid, deposit, {from: _user});
            const poolInfo = await this.pool.userInfo(pid, _user);
            const depositedAmount = poolInfo.amount.toString();
            // any amount
            expect(depositedAmount).to.be.equal(deposit.toString());

            const balanceOf = await this.token.balanceOf(_user, {from: _user});
            const expected_balance = new BN(web3.utils.toWei('0')).toString();
            expect(balanceOf.toString()).to.be.equal( expected_balance );

            time.advanceBlock();

            const pendingReward = await this.pool.pendingReward( pid, _user, {from: _user} );
            const reward = pendingReward.toString();
            console.log('reward', reward);

        });



    });

});
