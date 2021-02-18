pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: SimPL-2.0

import "../interface/IERC20.sol";

import "./StakeBase.sol";

contract StakeERC20 is StakeBase {
    IERC20 public moneyIn;

    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _reward,
        uint256 _perReward,
        address _moneyIn
    ) StakeBase(_startTime, _duration, _reward, _perReward) {
        moneyIn = IERC20(_moneyIn);
    }

    function _onMortgageAdd(uint256 amount)
        internal
        override
        returns (uint256)
    {
        require(
            moneyIn.transferFrom(msg.sender, address(this), amount),
            "money transfer failed"
        );

        return 0;
    }

    function _onMortgageSub(uint256 amount) internal override {
        require(moneyIn.transfer(msg.sender, amount), "money transfer failed");
    }

    function getTopHundreds() public view returns (UserLp[] memory) {
        uint256 len = lpBalancesList.length;
        UserLp[] memory top = new UserLp[](len);
        for (uint256 i = 0; i < lpBalancesList.length; i++) {
            address user = indexedUser[i + 1];
            uint256 lpAmount = lpBalancesList[i];
            top[i] = UserLp(lpAmount, user);
        }
        return top;
    }
}
