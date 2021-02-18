pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC20.sol";

import "./MortgageBase.sol";
import "./lib/UInteger.sol";

contract CardMine is MortgageBase {
    using UInteger for uint256;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _reward,
        uint256 _perReward
    ) MortgageBase(_startTime, _duration, _reward, _perReward) {}

    function updateFight(address owner, int256 fight) external {
        require(
            msg.sender == manager.members("slot"),
            "slot update fight only"
        );

        int256 amount = fight - mortgageAmounts[owner];
        _mortgage(owner, amount, 1);
    }

    function withdraw() external {
        uint256 ratio = 1;
        uint256 reward = _withdraw(ratio);

        uint256 fundReward = reward.mul(3).div(100);

        // not check result to save gas
        IERC20(manager.members("token")).transfer(msg.sender, reward);

        if (fundAddr != msg.sender) {
            IERC20(manager.members("token")).transfer(fundAddr, fundReward);
        }
    }
}