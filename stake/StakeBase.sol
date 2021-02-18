pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/IERC20.sol";
import "../interface/ISwapRouter.sol";

import "../lib/UInteger.sol";
import "../lib/Util.sol";

import "../MortgageBase.sol";

import "../shop/ShopExchange.sol";

abstract contract StakeBase is ShopExchange, MortgageBase {
    using UInteger for uint256;

    bool public isRunning = true;
    bool public isRanking = true;

    struct UserLp {
        uint256 amount;
        address account;
    }

    mapping(address => uint256) public userIndex;
    mapping(uint256 => address) public indexedUser;
    uint256[] public lpBalancesList;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _reward,
        uint256 _perReward
    ) MortgageBase(_startTime, _duration, _reward, _perReward) {}

    function setRunning(bool running) external CheckPermit("Admin") {
        isRunning = running;
    }

    function setRanking(bool ranking) external CheckPermit("Admin") {
        isRanking = ranking;
    }

    function _onMortgageAdd(uint256 amount) internal virtual returns (uint256);

    function mortgageAdd(uint256 amount) external payable {
        require(isRunning, "mortgage not running");
        uint256 ratio = 4;
        if (isRanking) {
            (, ratio, ) = calcRank(msg.sender);

            uint256 newAmount =
                uint256(mortgageAmounts[msg.sender]).add(amount);

            if (userIndex[msg.sender] == 0) {
                if (lpBalancesList.length >= 100) {
                    uint256[] memory sortedList = sort(lpBalancesList);
                    uint256 min = sortedList[sortedList.length - 1];
                    if (newAmount > min) {
                        uint256 pos = _getIndex(min, lpBalancesList);
                        address user = indexedUser[pos + 1];

                        lpBalancesList[pos] = newAmount;
                        userIndex[msg.sender] = pos + 1;
                        indexedUser[pos + 1] = msg.sender;

                        delete userIndex[user];
                    }
                } else {
                    lpBalancesList.push(newAmount);
                    userIndex[msg.sender] = lpBalancesList.length;
                    indexedUser[lpBalancesList.length] = msg.sender;
                }
            } else {
                uint256 ui = userIndex[msg.sender];
                lpBalancesList[ui - 1] = newAmount;
            }
        }

        _onMortgageAdd(amount);

        _mortgage(msg.sender, int256(amount), ratio);
    }

    function _onMortgageSub(uint256 amount) internal virtual;

    function mortgageSub(uint256 amount) external {
        uint256 ratio = 4;
        if (isRanking) {
            (, ratio, ) = calcRank(msg.sender);

            uint256 ui = userIndex[msg.sender];
            if (ui > 0) {
                uint256 leftover =
                    uint256(mortgageAmounts[msg.sender]).sub(amount);
                lpBalancesList[ui - 1] = leftover;
                if (leftover == 0) {
                    uint256 last = lpBalancesList[lpBalancesList.length - 1];
                    address lastUser = indexedUser[lpBalancesList.length];

                    lpBalancesList[ui - 1] = last;
                    userIndex[lastUser] = ui;
                    indexedUser[ui] = lastUser;

                    lpBalancesList.pop();

                    delete userIndex[msg.sender];
                }
            }
        }
        _mortgage(msg.sender, -int256(amount), ratio);

        _onMortgageSub(amount);
    }

    function _calcEarned(address owner) internal returns (int256) {
        (, uint256 ratio, ) = calcRank(owner);
        int256 initialEarned = super._calcReward(owner, ratio);
        if (initialEarned < 0) {
            initialEarned = 0;
        }

        return initialEarned;
    }

    function buy(uint256 tokenAmount, uint256 quantity) external {
        address owner = msg.sender;

        uint256 cost = tokenAmount.mul(quantity);

        int256 mortgageReward = _calcEarned(owner);

        uint256 reward = uint256(mortgageReward);

        if (cost > reward) {
            require(
                block.timestamp > startTime + totalDuration,
                "mine not over and tokenAmount not enough"
            );

            IERC20(manager.members("token")).transferFrom(
                owner,
                address(this),
                cost - reward
            );
            mortgageAdjusts[owner] = 0;
            if (owner != fundAddr) {
                uint256 fundReward = reward.mul(3).div(100);
                mortgageAdjusts[fundAddr] += int256(fundReward);
            }
        } else {
            mortgageAdjusts[owner] -= int256(cost);

            if (owner != fundAddr) {
                uint256 fundReward = cost.mul(3).div(100);
                mortgageAdjusts[fundAddr] += int256(fundReward);
            }
        }

        _buyExchange(address(0), tokenAmount, quantity, 0);
    }

    function sort(uint256[] memory data)
        public
        view
        returns (uint256[] memory)
    {
        if (data.length <= 1) {
            return data;
        }
        _quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function _getIndex(uint256 num, uint256[] memory data)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < data.length; i++) {
            if (num == data[i]) return i;
        }
        return 160;
    }

    function _quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] > pivot) i++;
            while (pivot > arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    function calcRank(address user)
        public
        view
        returns (
            uint256 rank,
            uint256 ratio,
            uint256[] memory sortedList
        )
    {
        uint256 bal = uint256(mortgageAmounts[user]);
        uint256[] memory list = lpBalancesList;
        sortedList = sort(list);

        rank = _getIndex(bal, sortedList) + 1;
        if (lpBalancesList.length >= 100) {
            if (rank <= 30) {
                ratio = 3;
            } else if (rank > 30 && rank <= 50) {
                // 30 - 50
                ratio = 5;
            } else if (rank > 50 && rank <= 80) {
                // 51 - 80
                ratio = 4;
            } else {
                ratio = 2;
            }
        } else {
            ratio = 2;
        }
    }

    function getLpBalancesList() external view returns (uint256[] memory) {
        return lpBalancesList;
    }
}
