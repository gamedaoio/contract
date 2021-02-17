pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

interface IEDC {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function stake() external payable;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}