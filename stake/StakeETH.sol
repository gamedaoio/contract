pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: SimPL-2.0

import "./StakeBase.sol";

contract StakeETH is StakeBase {
    constructor(
        uint256 _startTime,
        uint256 _duration,
        uint256 _reward,
        uint256 _perReward
    ) StakeBase(_startTime, _duration, _reward, _perReward) {}

    receive() external payable {}

    function _onMortgageAdd(uint256 amount)
        internal
        override
        returns (uint256)
    {
        require(msg.value == amount, "invalid amount");
        return amount;
    }

    function _onMortgageSub(uint256 amount) internal override {
        address payable sender = payable(msg.sender);
        sender.transfer(amount);
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
