const web3 = require('web3');
const {accounts, contract} = require('@openzeppelin/test-environment');
const {BN, expectRevert, time, expectEvent, constants} = require('@openzeppelin/test-helpers');
const {expect} = require('chai');
const Token = contract.fromArtifact('AfterLife');
const NFT = contract.fromArtifact('NFT');
const NftFarm = contract.fromArtifact('NftFarm');
let dev, user;
const mintAmount = '1';
const _name = 'Life';//
const _symbol = 'ALIFE';
const baseURI = 'ipfs://';
const ipfsHash = 'QmWB5xPBcFRn8qR4uu1VHt1k9vUrxvbezYv3jDC7WD29ie';

const supply = web3.utils.toWei('6666');
const totalSupplyDistributed = '6666';
const price = '66';
const alifePerBurn = web3.utils.toWei(price);
const startBlock = 0;
const endBlockNumber = 0;
const allowMultipleClaims = true;
const rarity = "Common";

const maxMintPerNft = '666';
const priceMultiplier = '0';

const min_interval = 0;
const max_interval = 3;

describe('NftMinting', function () {
    beforeEach(async function () {
        dev = accounts[0];
        user = accounts[1];
        this.Token = await Token.new({from: dev});
        await this.Token.mint(dev, supply, {from: dev});
        this.NFT = await NFT.new(baseURI, {from: dev});
        this.NftFarm = await NftFarm.new(this.NFT.address, this.Token.address, {from: dev});
        await this.NFT.manageMinters(this.NftFarm.address, true, {from: dev});
        const isMinter = await this.NFT.minters(this.NftFarm.address, {from: dev});
        console.log('------------isMinter', isMinter);
    });

    describe('mint', function () {

        it('MUST HAVE TOKEN', async function () {
            const _nftId='0', _author = user, _startBlock = 1,
                _endBlock = '9999999999', _allowMng = true,
                _rarity = "basic", _uri = "localhost/basic", _authorFee = '3000',
                _authorName = "user", _authorTwitter = "@user", _status = "1";

            await this.NftFarm.add(_nftId, _author, _startBlock,
                _endBlock, _allowMng, _rarity, _uri, _authorFee,
                _authorName, _authorTwitter, _status, {from: dev});

            await this.NftFarm.mint(_nftId, {from: dev});
            const ownersOf = await this.NftFarm.getOwnersOf(_nftId, {from: dev});
            expect(ownersOf[0]).to.be.equal(dev);

        });
    });
        /*
            describe('mintNFT', function () {

                it('MUST HAVE TOKEN', async function () {
                    const nftId = 0;
                    await expectRevert(this.NftFarm.mintNFT(nftId, {from: user}), 'transfer amount exceeds balance');
                });
                it('MUST MINT WITH BALANCE', async function () {
                    const balance = await this.Token.balanceOf(dev);
                    expect(balance).to.be.bignumber.equal(supply);
                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    const nftId = 0;
                    await this.NftFarm.mintNFT(0, {from: dev});
                    const ownersOf = await this.NftFarm.getOwnersOf(nftId, {from: dev});
                    expect(ownersOf[0]).to.be.equal(dev);

                    const getClaimedAmount = await this.NftFarm.getClaimedAmount(nftId, {from: dev});
                    expect(getClaimedAmount.toString()).to.be.equal('1');

                    const getMinted = await this.NftFarm.getMinted(dev, {from: dev});

                    // nftId 0 at index 0
                    expect(getMinted[0][0].toString()).to.be.equal('0');

                    // nftId 0 amount minted at index 1
                    expect(getMinted[1][0].toString()).to.be.equal('1');

                    // nftId 0 last owner at index 2
                    expect(getMinted[2][0].toString()).to.be.equal(dev);

                });
            });

            describe('mintNFT', function () {
                it('MUST HAVE TOKEN', async function () {
                    await expectRevert(this.NftFarm.mintNFT(0, {from: user}), 'transfer amount exceeds balance');
                });
                it('MUST MINT 1 NFT WITH BALANCE', async function () {
                    const balance = await this.Token.balanceOf(dev);
                    expect(balance).to.be.bignumber.equal(supply);
                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    const nftId = 0;
                    await this.NftFarm.mintNFT(0, {from: dev});
                    const ownersOf = await this.NftFarm.getOwnersOf(nftId, {from: dev});
                    expect(ownersOf[0]).to.be.equal(dev);

                    const getClaimedAmount = await this.NftFarm.getClaimedAmount(nftId, {from: dev});
                    expect(getClaimedAmount.toString()).to.be.equal('1');

                    const getMinted = await this.NftFarm.getMinted(dev, {from: dev});

                    // nftId 0 at index 0
                    expect(getMinted[0][0].toString()).to.be.equal('0');

                    // nftId 0 amount minted at index 1
                    expect(getMinted[1][0].toString()).to.be.equal('1');

                    // nftId 0 last owner at index 2
                    expect(getMinted[2][0].toString()).to.be.equal(dev);

                });

                it('Get NFT metadata', async function () {
                    const balance = await this.Token.balanceOf(dev);
                    expect(balance).to.be.bignumber.equal(supply);
                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    const nftId = 0;
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    const tokenId = await this.NFT.getNftId(nftId, {from: dev});
                    const getNftName = await this.NFT.getNftName(tokenId, {from: dev});
                    const getNftNameOfTokenId = await this.NFT.getNftNameOfTokenId(tokenId, {from: dev});
                    expect(getNftName).to.be.equal("Common");
                    expect(getNftNameOfTokenId).to.be.equal("Common");

                    const balanceOf = await this.NFT.balanceOf(dev, {from: dev});
                    const ownerOf = await this.NFT.ownerOf(tokenId, {from: dev});
                    expect(balanceOf.toString()).to.be.equal("2");
                    expect(ownerOf).to.be.equal(dev);

                    const tokenURI = await this.NFT.tokenURI(tokenId, {from: dev});
                    expect(tokenURI).to.be.equal(baseURI + ipfsHash + '/0.json');

                });

                it('TEST NFT URI', async function () {
                    const balance = await this.Token.balanceOf(dev);
                    expect(balance).to.be.bignumber.equal(supply);
                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(0, {from: dev});
                    await this.NftFarm.mintNFT(1, {from: dev});
                    await this.NftFarm.mintNFT(2, {from: dev});

                    const tokenId0 = await this.NFT.getNftId(0, {from: dev});
                    const tokenURI0 = await this.NFT.tokenURI(tokenId0, {from: dev});
                    expect(tokenURI0).to.be.equal(baseURI + ipfsHash + '/0.json');

                    const tokenId1 = await this.NFT.getNftId(1, {from: dev});
                    const tokenURI1 = await this.NFT.tokenURI(tokenId1, {from: dev});
                    expect(tokenURI1).to.be.equal(baseURI + ipfsHash + '/1.json');

                    const tokenId2 = await this.NFT.getNftId(2, {from: dev});
                    const tokenURI2 = await this.NFT.tokenURI(tokenId2, {from: dev});
                    expect(tokenURI2).to.be.equal(baseURI + ipfsHash + '/2.json');

                });

                it('TEST DEFAULT PRICE', async function () {
                    const nftId = 0;
                    const getPrice = await this.NftFarm.getPrice(nftId, 1, {from: user});
                    expect(getPrice).to.be.bignumber.equal(alifePerBurn);
                });
                it('TEST PRICE BY NFT', async function () {
                    const nftId = 0;
                    const newPrice = web3.utils.toWei('1000');
                    await this.NftFarm.adminSetPriceByNftId(nftId, newPrice, {from: dev});
                    const getPrice = await this.NftFarm.getPrice(nftId, 1, {from: user});
                    expect(getPrice).to.be.bignumber.equal(newPrice);
                });

                it('TEST PRICE MULTIPLIER', async function () {
                    const nftId = 0;
                    const multiplier = '2000000';
                    await this.NftFarm.adminSetMultiplier(multiplier, {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    const getPrice1 = await this.NftFarm.getPrice(nftId, 1, {from: user});
                    const total = web3.utils.toWei('132');
                    expect(getPrice1).to.be.bignumber.equal(total);
                });


            });


            describe('NFT MINTING LIMITS', function () {
                it('TEST allowMultipleClaims', async function () {
                    const nftId = 0;

                    await this.NftFarm.adminSetAllowMultipleClaims(true, {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});

                    await this.NftFarm.adminSetAllowMultipleClaims(false, {from: dev});

                    await expectRevert(this.NftFarm.mintNFT(nftId, {from: dev}), "Has claimed");
                });
                it('TEST maxMintPerNft=3', async function () {
                    const nftId = 0;


                    await this.NftFarm.adminSetMaxMintPerNft('3', {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    const getClaimedAmount = await this.NftFarm.getClaimedAmount(nftId, {from: dev});
                    expect(getClaimedAmount.toString()).to.be.bignumber.equal('3');

                    await expectRevert(this.NftFarm.mintNFT(nftId, {from: dev}), "Max minting reached");
                });
                it('TEST mint_by_nftId[_nftId]=3', async function () {
                    const nftId = 0;

                    await this.NftFarm.adminSetMaxMintByNftId(nftId, 3, {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    await this.NftFarm.mintNFT(nftId, {from: dev});
                    const getClaimedAmount = await this.NftFarm.getClaimedAmount(nftId, {from: dev});
                    expect(getClaimedAmount.toString()).to.be.bignumber.equal('3');

                    await expectRevert(this.NftFarm.mintNFT(nftId, {from: dev}), "Max minting by NFT reached");
                });
                it('TEST totalSupplyDistributed=3', async function () {
                    const nftId = 0;

                    await this.NftFarm.adminSetTotalSupply(3, {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(0, {from: dev});
                    await this.NftFarm.mintNFT(1, {from: dev});
                    await this.NftFarm.mintNFT(2, {from: dev});

                    await expectRevert(this.NftFarm.mintNFT(3, {from: dev}), "Nothing left");

                    const total = await this.NftFarm.currentDistributedSupply({from: dev});
                    expect(total.toString()).to.be.bignumber.equal('3');

                });
            });


            describe('ADMIN SECURITY TESTS', function () {
                it('adminSetInterval', async function () {
                    await expectRevert(this.NftFarm.adminSetInterval(0, 0, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetInterval(0, 0, {from: dev});
                });
                it('adminSetPriceByNftId', async function () {
                    await expectRevert(this.NftFarm.adminSetPriceByNftId(0, 1, {from: user}), 'Managers: not a manager');
                    await this.NftFarm.adminSetPriceByNftId(0, 1, {from: dev});
                });
                it('adminSetInterval', async function () {
                    await expectRevert(this.NftFarm.adminSetMintingInterval(0, 1, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetMintingInterval(0, 6, {from: dev});
                });
                it('adminSetMaxMintByNftId', async function () {
                    await expectRevert(this.NftFarm.adminSetMaxMintByNftId(0, '1', {from: user}), 'Managers: not a manager');
                    await this.NftFarm.adminSetMaxMintByNftId(0, '1', {from: dev});
                });
                it('adminSetMaxMintPerNft', async function () {
                    await expectRevert(this.NftFarm.adminSetMaxMintPerNft(1, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetMaxMintPerNft(1, {from: dev});
                });
                it('adminSetMultiplier', async function () {
                    await expectRevert(this.NftFarm.adminSetMultiplier(1, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetMultiplier(1, {from: dev});
                });
                it('adminSetMintingManager', async function () {
                    await expectRevert(this.NftFarm.adminSetMintingManager(user, true, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetMintingManager(user, true, {from: dev});
                });
                it('adminSetAllowMultipleClaims', async function () {
                    await expectRevert(this.NftFarm.adminSetAllowMultipleClaims(true, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetAllowMultipleClaims(true, {from: dev});
                });
                it('adminChangeToken', async function () {
                    await expectRevert(this.NftFarm.adminChangeToken(this.Token.address, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminChangeToken(this.Token.address, {from: dev});
                });
                it('adminSetTotalSupply', async function () {
                    await expectRevert(this.NftFarm.adminSetTotalSupply(totalSupplyDistributed, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetTotalSupply(totalSupplyDistributed, {from: dev});
                });
                it('adminSetTokenPerBurn', async function () {
                    const tokenPerBurn = web3.utils.toWei('6');
                    await expectRevert(this.NftFarm.adminSetTokenPerBurn(tokenPerBurn, {from: user}), 'Ownable: caller is not the owner');
                    await this.NftFarm.adminSetTokenPerBurn(tokenPerBurn, {from: dev});
                });
                it('adminSetBaseURI', async function () {
                    const baseURI = 'ipfs://';
                    await expectRevert(this.NftFarm.adminSetBaseURI(baseURI, {from: user}), 'Ownable: caller is not the owner');
                    const owner = await this.NftFarm.owner();
                    await this.NftFarm.adminSetBaseURI(baseURI, {from: dev});
                });
                it('adminSetPriceMultiplierByNftId', async function () {
                    await expectRevert(this.NftFarm.adminSetPriceMultiplierByNftId(0, new BN('1.1'), {from: user}), 'Managers: not a manager');
                    await this.NftFarm.adminSetPriceMultiplierByNftId(0, new BN('1.1'), {from: dev});
                });
            });


            describe('NFT MINTING INFO AND COUNTS', function () {
                it('TEST getMinted INFO', async function () {
                    await this.NftFarm.adminSetMaxMintPerNft(3, {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(0, {from: dev});
                    await this.NftFarm.mintNFT(0, {from: dev});
                    await this.NftFarm.mintNFT(0, {from: dev});
                    const getClaimedAmount = await this.NftFarm.getClaimedAmount(0, {from: dev});
                    expect(getClaimedAmount.toString()).to.be.bignumber.equal('3');
                    await expectRevert(this.NftFarm.mintNFT(0, {from: dev}), "Max minting reached");

                    const getMinted = await this.NftFarm.getMinted(dev, {from: dev});

                    const minted = getMinted[0];
                    const mintedAmounts = getMinted[1];
                    const lastOwner = getMinted[2];
                    const maxMintByNft = getMinted[3];
                    const prices = getMinted[4];
                    const myMints = getMinted[5];

                    expect(minted[0]).to.be.bignumber.equal('0');
                    expect(mintedAmounts[0]).to.be.bignumber.equal('3');
                    expect(lastOwner[0]).to.be.equal(dev);
                    expect(maxMintByNft[0]).to.be.bignumber.equal('3');
                    expect(prices[0]).to.be.bignumber.equal(web3.utils.toWei(price));
                    expect(myMints[0]).to.be.bignumber.equal('3');

                    const alifePerBurn10 = web3.utils.toWei('132');
                    await this.Token.mint(user, supply, {from: dev});
                    await this.Token.approve(this.NftFarm.address, supply, {from: user});

                    await this.NftFarm.mintNFT(1, {from: user});
                    await this.NftFarm.mintNFT(1, {from: user});


                    const getMinteduser = await this.NftFarm.getMinted(user, {from: user});

                    const minteduser = getMinteduser[0];
                    const mintedAmountsuser = getMinteduser[1];
                    const lastOwneruser = getMinteduser[2];
                    const maxMintByNftuser = getMinteduser[3];
                    const pricesuser = getMinteduser[4];
                    const myMintsuser = getMinteduser[5];

                    expect(minteduser[1]).to.be.bignumber.equal('1');
                    expect(mintedAmountsuser[1]).to.be.bignumber.equal('2');
                    expect(lastOwneruser[1]).to.be.equal(user);
                    expect(maxMintByNftuser[1]).to.be.bignumber.equal('3');
                    expect(pricesuser[1]).to.be.bignumber.equal(web3.utils.toWei(price));
                    expect(myMintsuser[1]).to.be.bignumber.equal('2');
                });
            });
            describe('NFT MINTING INTERVAL', function () {
                it('TEST MINTING LIMITS', async function () {
                    await this.NftFarm.adminSetMaxMintPerNft(3, {from: dev});
                    await this.NftFarm.adminSetMintingInterval(0, 2, {from: dev});

                    await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                    await this.NftFarm.mintNFT(0, {from: dev});
                    await this.NftFarm.mintNFT(1, {from: dev});
                    await this.NftFarm.mintNFT(2, {from: dev});
                    await expectRevert(this.NftFarm.mintNFT(3, {from: dev}), "Out of minting interval");

                });
            });

        describe('NFT MINTING BONDING CURVE', function () {

            it('1x price does not change on mint', async function () {

                await this.NftFarm.adminSetMaxMintPerNft(3, {from: dev});

                const priceNft0 = web3.utils.toWei('1');
                await this.NftFarm.adminSetPriceMultiplierByNftId(0, 0, {from: dev});
                await this.NftFarm.adminSetPriceByNftId(0, priceNft0, {from: dev});

                await this.Token.approve(this.NftFarm.address, supply, {from: dev});

                const price0Wei = (await this.NftFarm.getPrice(0, 1, {from: dev})).toString();

                expect(price0Wei).to.be.bignumber.equal(price0Wei);

                // 1x price does not change
                await this.NftFarm.mintNFT(0, {from: dev});
                const price0WeiAfterMint0 = (await this.NftFarm.getPrice(0, 1, {from: dev})).toString();
                expect(price0WeiAfterMint0).to.be.bignumber.equal(price0Wei);

                await this.NftFarm.mintNFT(0, {from: dev});
                const price0WeiAfterMint1 = (await this.NftFarm.getPrice(0, 2, {from: dev})).toString();
                expect(price0WeiAfterMint1).to.be.bignumber.equal(price0Wei);

                await this.NftFarm.mintNFT(0, {from: dev});
                const price0WeiAfterMint2 = (await this.NftFarm.getPrice(0, 3, {from: dev})).toString();
                expect(price0WeiAfterMint2).to.be.bignumber.equal(price0Wei);
            });

            it('2x price change on mint of 1 index', async function () {

                await this.Token.approve(this.NftFarm.address, supply, {from: dev});
                await this.NftFarm.adminSetMaxMintPerNft(3, {from: dev});


                const priceNft0 = web3.utils.toWei('350');
                await this.NftFarm.adminSetTokenPerBurn(priceNft0, {from: dev});

                const MULTIPLIER = '1016282';
                await this.NftFarm.adminSetPriceMultiplierByNftId(0, MULTIPLIER, {from: dev});
                await this.NftFarm.adminSetPriceByNftId(0, priceNft0, {from: dev});

                expect('350.00').to.be.bignumber.equal(parseFloat(web3.utils.fromWei((await this.NftFarm.getPrice(0, 0, {from: dev})).toString())).toFixed(2));
                expect('355.70').to.be.bignumber.equal(parseFloat(web3.utils.fromWei((await this.NftFarm.getPrice(0, 1, {from: dev})).toString())).toFixed(2));
                expect('361.49').to.be.bignumber.equal(parseFloat(web3.utils.fromWei((await this.NftFarm.getPrice(0, 2, {from: dev})).toString())).toFixed(2));
                expect('367.38').to.be.bignumber.equal(parseFloat(web3.utils.fromWei((await this.NftFarm.getPrice(0, 3, {from: dev})).toString())).toFixed(2));


                expect(await this.NftFarm.getPrice(1, 1, {from: dev})).to.be.bignumber.equal(priceNft0);

                // 3st mint: 2x price does not change
                await this.NftFarm.mintNFT(1, {from: dev});
                expect(await this.NftFarm.getPrice(1, 2, {from: dev})).to.be.bignumber.equal(priceNft0);

                // 1x price does not change
                await this.NftFarm.mintNFT(1, {from: dev});
                await this.NftFarm.mintNFT(1, {from: dev});
                await expectRevert(this.NftFarm.mintNFT(1, {from: dev}),"Max minting reached");
                expect(await this.NftFarm.getPrice(1, 4, {from: dev})).to.be.bignumber.equal(priceNft0);


            });

        });
        */
});
