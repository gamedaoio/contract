pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "./interface/IERC20.sol";

import "./Member.sol";

abstract contract MortgageBase is Member {
    uint256 public startTime;
    uint256 public totalDuration;
    uint256 public totalReward;
    uint256 public perReward;
    uint256 public mortgageNumber = 0;

    address public fundAddr;

    int256 public mortgageMax = 10**30;

    mapping(address => int256) public mortgageAmounts;
    mapping(address => int256) public mortgageAdjusts;
    mapping(address => uint256) public mortgageTimes;

    int256 public totalAmount;
    int256 public totalAdjust;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _reward,
        uint256 _perReward
    ) {
        startTime = _startTime;
        totalDuration = _duration;
        totalReward = _reward;
        perReward = _perReward;
    }

    function setTimeStart(uint256 _startTime) external CheckPermit("Config") {
        startTime = _startTime;
    }

    function setFundAddr(address addr) external CheckPermit("Config") {
        fundAddr = addr;
    }

    function setMortgageMax(int256 max) external CheckPermit("Config") {
        mortgageMax = max;
    }

    function getMineInfo()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            int256,
            int256,
            uint256,
            uint256
        )
    {
        return (
            startTime,
            totalDuration,
            totalReward,
            totalAmount,
            totalAdjust,
            perReward,
            mortgageNumber
        );
    }

    function getMyMineInfo(address owner)
        public
        view
        returns (
            int256,
            int256,
            int256,
            uint256
        )
    {
        int256 amount = mortgageAmounts[owner];

        uint256 _now = block.timestamp;
        if (_now <= startTime) {
            return (amount, 0, 0, 0);
        }

        int256 reward = 0;
        uint256 lasttime = mortgageTimes[owner];
        if (lasttime > 0 && totalAmount > 0) {
            uint256 t = _now - lasttime;
            if (_now > startTime + totalDuration) {
                t = startTime + totalDuration - lasttime;
            }

            reward = int256(t) * ((int256(perReward) * amount) / totalAmount);
        }

        return (amount, mortgageAdjusts[owner], reward, mortgageTimes[owner]);
    }

    function _mortgage(
        address owner,
        int256 amount,
        uint256 ratio
    ) internal {
        int256 _amount = mortgageAmounts[owner];
        int256 newAmount = mortgageAmounts[owner] + amount;
        require(newAmount >= 0 && newAmount < mortgageMax, "invalid amount");

        uint256 _now = block.timestamp;
        require(_now > startTime, "time not yet");
        uint256 lasttime = mortgageTimes[owner];
        if (lasttime > 0 && totalAmount > 0) {
            uint256 t = _now - lasttime;
            int256 _perReward = int256(perReward);

            if (_now > startTime + totalDuration) {
                t = startTime + totalDuration - lasttime;

                if (totalAdjust > int256(totalReward)) {
                    _perReward = 0;
                } else {
                    _perReward =
                        (int256(totalReward) - totalAdjust) /
                        int256(totalDuration);
                }
            }

            int256 adjust =
                int256(t) *
                    ((int256(_perReward) * _amount) / totalAmount) *
                    int256(ratio);
            mortgageAdjusts[owner] += adjust;
            totalAdjust += adjust;
            mortgageTimes[owner] = _now;
        } else {
            mortgageTimes[owner] = _now;
            mortgageNumber++;
        }

        mortgageAmounts[owner] = newAmount;
        totalAmount += amount;
    }

    function _calcReward(address owner, uint256 ratio)
        internal
        returns (int256)
    {
        uint256 _now = block.timestamp;
        if (_now <= startTime) {
            return 0;
        }

        int256 amount = mortgageAmounts[owner];
        if (amount == 0) {
            return mortgageAdjusts[owner];
        }

        // int256 reward;

        uint256 lasttime = mortgageTimes[owner];
        if (lasttime > 0) {
            uint256 t = _now - lasttime;
            int256 _perReward = int256(perReward);

            if (_now > startTime + totalDuration) {
                t = startTime + totalDuration - lasttime;

                if (totalAdjust > int256(totalReward)) {
                    _perReward = 0;
                } else {
                    _perReward =
                        (int256(totalReward) - totalAdjust) /
                        int256(totalDuration);
                }
            }

            int256 _adjust =
                int256(t) *
                    ((_perReward * amount) / totalAmount) *
                    int256(ratio);

            mortgageAdjusts[owner] += _adjust;
            totalAdjust += _adjust;
            mortgageTimes[owner] = _now;
        }

        return mortgageAdjusts[owner];
    }

    function _withdraw(uint256 ratio) internal returns (uint256) {
        int256 reward = _calcReward(msg.sender, ratio);
        require(reward > 0, "no reward");

        mortgageAdjusts[msg.sender] -= reward;
        return uint256(reward);
    }

    function stopMortgage() external CheckPermit("Admin") {
        uint256 _now = block.timestamp;
        require(_now < startTime + totalDuration, "mortgage over");

        uint256 tokenAmount;

        if (_now < startTime) {
            tokenAmount = totalReward;
            totalReward = 0;
            totalDuration = 1;
        } else {
            uint256 reward = (totalReward * (_now - startTime)) / totalDuration;
            tokenAmount = totalReward - reward;
            totalReward = reward;
            totalDuration = _now - startTime;
        }

        IERC20(manager.members("token")).transfer(
            manager.members("cashier"),
            tokenAmount
        );
    }
}
