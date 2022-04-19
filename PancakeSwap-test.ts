import {ethers, waffle} from "hardhat"
import {Signer, Contract, ContractFactory, BigNumber} from "ethers"
import chai from "chai"
import {solidity} from "ethereum-waffle"
import type {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers"
import {
    IUniswapV2Pair__factory,
    IUniswapV2Router02__factory,
    IUniswapV2Router02,
    IUniswapV2Factory,
    IUniswapV2Factory__factory,
    Mock1ERC20,
    Mock1ERC20__factory,
    Mock2ERC20__factory,
    Mock2ERC20, IUniswapV2Pair
} from "../typechain";

chai.use(solidity)
const {expect} = chai

function ether(eth: string) {
    let weiAmount = ethers.utils.parseEther(eth)
    return weiAmount;
}

async function getLatestBlockTimestamp() {
    return (await ethers.provider.getBlock("latest")).timestamp || 0
}

describe("Swap on pancake", async function () {
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let Mock1ERC20: Mock1ERC20__factory;
    let mock1ERC20: Mock1ERC20;
    let Mock2ERC20: Mock2ERC20__factory;
    let mock2ERC20: Mock2ERC20;

    let uniswapV2Factory: IUniswapV2Factory;
    let uniswapV2Router: IUniswapV2Router02;
    let uniswapV2Pair: IUniswapV2Pair;

    beforeEach("Deploy the contract", async function () {
        [owner, user1] = await ethers.getSigners();

        uniswapV2Router = IUniswapV2Router02__factory.connect("0x10ED43C718714eb63d5aA57B78B54704E256024E", owner);
        uniswapV2Factory = IUniswapV2Factory__factory.connect("0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73", owner);

        Mock1ERC20 = new Mock1ERC20__factory(owner);
        Mock2ERC20 = new Mock2ERC20__factory(owner);

        mock1ERC20 = await Mock1ERC20.deploy(10 ** 7);
        await mock1ERC20.deployed();

        mock2ERC20 = await Mock2ERC20.deploy(10 ** 7);
        await mock2ERC20.deployed();
    });

    describe("Swap on Pancake", async function () {
        beforeEach("DEX preparation", async () => {
            expect(await mock1ERC20.balanceOf(owner.address)).to.equal(ether("10000000"));

            expect(await uniswapV2Factory.createPair(mock1ERC20.address, mock2ERC20.address)).to.ok;
            uniswapV2Pair = IUniswapV2Pair__factory.connect(await uniswapV2Factory.getPair(mock1ERC20.address, mock2ERC20.address), owner)

            let mock1ERC20Liquididty = ether("1000000")
            let mock2ERC20Liquididty = ether("100000")

            expect(await mock1ERC20.approve(uniswapV2Router.address, mock1ERC20Liquididty)).to.ok;
            expect(await mock2ERC20.approve(uniswapV2Router.address, mock2ERC20Liquididty)).to.ok;

            expect(await uniswapV2Router.addLiquidity(
                mock1ERC20.address, mock2ERC20.address, mock1ERC20Liquididty, mock2ERC20Liquididty,
                mock1ERC20Liquididty, mock2ERC20Liquididty, uniswapV2Pair.address, (await getLatestBlockTimestamp()) + 100_000)).to.ok;

            expect(await mock1ERC20.balanceOf(uniswapV2Pair.address)).to.equal(mock1ERC20Liquididty)
            expect(await mock2ERC20.balanceOf(uniswapV2Pair.address)).to.equal(mock2ERC20Liquididty)
        })

        it("swapTokensForExactTokens: mock1ERC20 => mock2ERC20", async function () {
            let mockTokenAmountIn = ether("50000")
            let mock1ERC20AmountOut = (await uniswapV2Router.getAmountsOut(mockTokenAmountIn, [mock1ERC20.address, mock2ERC20.address]))[1]

            let ownerTokenBalanceBefore = await mock1ERC20.balanceOf(owner.address)

            expect(await mock2ERC20.approve(uniswapV2Router.address, mockTokenAmountIn)).to.ok;
            expect(await mock1ERC20.approve(uniswapV2Router.address, mock1ERC20AmountOut)).to.ok;

            expect(await uniswapV2Router.swapTokensForExactTokens(mock1ERC20AmountOut, mockTokenAmountIn,
                [mock2ERC20.address, mock1ERC20.address], owner.address, (await getLatestBlockTimestamp()) + 100_000)
            ).to.ok;

            let ownerTokenBalanceAfter = await mock1ERC20.balanceOf(owner.address)

            //expect(ownerTokenBalanceAfter.sub(ownerTokenBalanceBefore)).to.be.equal(0);
        });
    });
});