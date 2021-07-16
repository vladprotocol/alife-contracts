const web3 = require('web3');
const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, time, expectEvent, constants} = require('@openzeppelin/test-helpers');
const {expect} = require('chai');
const Token = contract.fromArtifact('AfterLife');
const NFT = contract.fromArtifact('NFT');
const NftFarm = contract.fromArtifact('NftFarmV2');
let dev, user, userx;
const mintAmount = '1';
const _name = 'Life';//
const _symbol = 'ALIFE';
const baseURI = 'ipfs://';
const ipfsHash = 'QmWB5xPBcFRn8qR4uu1VHt1k9vUrxvbezYv3jDC7WD29ie';

const supply = web3.utils.toWei('100000');
const totalSupplyDistributed = '100';
const price = web3.utils.toWei('1');
const halfPrice = web3.utils.toWei('0.5');
const doublePrice = web3.utils.toWei('2');
const alifePerBurn = web3.utils.toWei(price);
const startBlock = 0;
const endBlockNumber = 0;
const allowMultipleClaims = true;
const rarity = "Common";

const maxMintPerNft = '666';
const priceMultiplier = '0';

const min_interval = 0;
const max_interval = 3;

function arrayBn2S(array) {
    if (!array) return;
    const length = array.length;
    if (length == 0) return;
    let newArray = [];
    for (let i = 0; i < length; i++) {
        newArray.push(array[i].toString());
    }
    return newArray;
}

describe('NftMinting', function () {
    beforeEach(async function () {
        this.timeout(60000);
        dev = accounts[0];
        user = accounts[1];
        userx = accounts[2];
        this.Token = await Token.new({from: dev});
        await this.Token.setMinterStatus(dev, true, {from: dev});
        await this.Token.mint(dev, supply, {from: dev});
        await this.Token.mint(user, supply, {from: dev});
        await this.Token.mint(userx, supply, {from: dev});
        this.NFT = await NFT.new(baseURI, {from: dev});
        this.NftFarm = await NftFarm.new(this.NFT.address, this.Token.address, {from: dev});
        await this.NFT.manageMinters(this.NftFarm.address, true, {from: dev});
        const isMinter = await this.NFT.minters(this.NftFarm.address, {from: dev});
        expect(isMinter).to.be.equal(true);

    });


    describe('mintNFT', function () {
        it('TEST PRICE MULTIPLIER', async function () {
            this.timeout(60000);
            const nftId = 1, _author = dev, _startBlock = 1,
                _endBlock = '9999999999', _allowMng = true, _uri = "localhost/basic",
                _authorFee = '3000', _status = "1";

            await this.NftFarm.add(nftId, _author, _startBlock,
                _endBlock, _allowMng, "rarityA", _uri, _authorFee,
                "dev", "@dev", _status, {from: dev});

            const nftPrice = web3.utils.toWei('1100');
            const nftMultiplier = '1114972';
            await this.NftFarm.setState(nftId, nftPrice, 5, nftMultiplier, {from: dev});
            await this.Token.approve(this.NftFarm.address, supply, {from: dev});
            console.log('balanceOf='+web3.utils.fromWei( (await this.Token.balanceOf(dev, {from: dev})) ))

            console.log('price #0='+web3.utils.fromWei( (await this.NftFarm.getPrice(1, 0, {from: dev})) ))
            console.log('state #0='+web3.utils.fromWei( (await this.NftFarm.nftInfoState(nftId, {from: dev})).price ))

            await this.NftFarm.mint(nftId, {from: dev});
            console.log('price #1='+web3.utils.fromWei( (await this.NftFarm.getPrice(1, 0, {from: dev})) ))
            console.log('state #1='+web3.utils.fromWei( (await this.NftFarm.nftInfoState(nftId, {from: dev})).price ))

            await this.NftFarm.mint(nftId, {from: dev});
            console.log('price #2='+web3.utils.fromWei( (await this.NftFarm.getPrice(1, 0, {from: dev})) ))
            console.log('state #2='+web3.utils.fromWei( (await this.NftFarm.nftInfoState(nftId, {from: dev})).price ))

            await this.NftFarm.mint(nftId, {from: dev});
            console.log('price #3='+web3.utils.fromWei( (await this.NftFarm.getPrice(1, 0, {from: dev})) ))
            console.log('state #3='+web3.utils.fromWei( (await this.NftFarm.nftInfoState(nftId, {from: dev})).price ))

            await this.NftFarm.mint(nftId, {from: dev});
            console.log('price #4='+web3.utils.fromWei( (await this.NftFarm.getPrice(1, 0, {from: dev})) ))
            console.log('state #4='+web3.utils.fromWei( (await this.NftFarm.nftInfoState(nftId, {from: dev})).price ))

            await this.NftFarm.mint(nftId, {from: dev});
            console.log('price #5='+web3.utils.fromWei( (await this.NftFarm.getPrice(1, 0, {from: dev})) ))
            console.log('state #6='+web3.utils.fromWei( (await this.NftFarm.nftInfoState(nftId, {from: dev})).price ))
        });
    });

});
