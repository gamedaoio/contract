pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/IEDC.sol";
import "../interface/IERC20.sol";
import "../interface/ISwapRouter.sol";

import "../lib/UInteger.sol";
import "../lib/Util.sol";

import "../shop/ShopRandom.sol";

contract ShopPresale is ShopRandom {
    uint256 public maxForSale = 4999;
    uint256 public sold = 0;

    IERC20 public money;

    uint256 public startTime;
    uint256 public endTime;

    constructor(
        address _money,
        uint256 _startTime,
        uint256 _endTime
    ) {
        money = IERC20(_money);
        startTime = _startTime;
        endTime = _endTime;
    }

    function buy(uint256 quantity) external {
        uint256 _now = block.timestamp;
        require(_now >= startTime, "it's hasn't started yet");
        require(_now <= endTime, "it's over");
        sold += quantity;
        require(sold <= maxForSale, "Shop: sold out");

        bool success =
            money.transferFrom(
                msg.sender,
                manager.members("cashier"),
                price * quantity
            );
        require(success, "transfer money failed");

        _buyRandom(quantity, 0);
    }

    function setMaxSale(uint256 number) external CheckPermit("Config") {
        maxForSale = number;
    }

    function getSold() external view returns (uint256) {
        return maxForSale - sold;
    }
}
