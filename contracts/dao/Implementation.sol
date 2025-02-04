/*
    Copyright 2021 1 Set Dollar Devs 

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Market.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "../Constants.sol";
import "../oracle/Pool.sol";

contract Implementation is State, Bonding, Market, Regulator, Govern {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    function initialize() initializer public {
        // Liquidity
        incentivize(address(0xaD0f2a2bCb61E1CbdA6b03F60D8D7290b092d430), 1000e18); // 1000 Tokens for liqidity

    }

    function advance() external {
        uint256 incentive = calculateReward();
        incentivize(msg.sender, incentive);

        Bonding.step();
        Regulator.step();
        Market.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    function incentivize(address account, uint256 amount) private {
        mintToAccount(account, amount);
        emit Incentivization(account, amount);
    }

    function calculateReward() public view returns(uint256) {
        uint256 price = calculatePrice();
        return Constants.getAdvanceIncentiveUSDC().mul(1e18).div(price);
    }

    function calculatePrice() public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(address(Pool(pool()).univ2()));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if (reserve0 == 0 || reserve1 == 0) return 0;

        (address token0, address token1) = (pair.token0(), pair.token1());
        uint256 price;

        if (token0 == address(dollar())) {
            price = reserve1.mul(1e18).div(reserve0);
        } else {
            price = reserve0.mul(1e18).div(reserve1);
        }

        return price;
    }
}
