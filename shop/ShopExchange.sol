pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "../lib/Util.sol";
import "../lib/UInteger.sol";

import "./Shop.sol";

abstract contract ShopExchange is Shop {
    using UInteger for uint256;

    uint256[] public rarityAmounts = [
        10**17 * 75,
        10**18 * 15,
        10**18 * 30,
        10**18 * 60,
        10**18 * 120
    ];

    function getRarityAmounts() public view returns (uint256[] memory) {
        return rarityAmounts;
    }

    function setRarityAmounts(uint256[] memory amounts)
        external
        CheckPermit("Config")
    {
        rarityAmounts = amounts;
    }

    function _buyExchange(
        address tokenSender,
        uint256 tokenAmount,
        uint256 quantity,
        uint256 padding
    ) internal {
        require(tokenAmount >= rarityAmounts[0], "too little token");

        _buy(msg.sender, tokenSender, tokenAmount, quantity, padding);
    }

    function onOpenPackage(
        address,
        uint256 packageId,
        bytes32 bh
    ) external view override returns (uint256[] memory) {
        uint256 intialAmount = uint64(packageId >> 160);
        uint256 tokenAmount = uint256(intialAmount).mul(1e10);
        uint256 quantity = uint16(packageId >> 144);

        uint256 length = rarityAmounts.length;
        uint256 rarity = 0;
        uint256 weight0 = 0;
        uint256 weight1 = 1;

        if (tokenAmount >= rarityAmounts[length - 1]) {
            rarity = length;
            weight0 = 999;
        } else {
            while (tokenAmount > rarityAmounts[rarity]) {
                ++rarity;
            }

            if (tokenAmount < rarityAmounts[rarity]) {
                weight0 = rarityAmounts[rarity] - tokenAmount;
                weight1 = tokenAmount - rarityAmounts[rarity - 1];
            }
        }

        uint256[] memory cardIdPres = new uint256[](quantity);

        for (uint256 i = 0; i != quantity; ++i) {
            uint256 cardType = calcCardType(abi.encode(bh, packageId, i));

            uint256 rar = rarity;

            if (weight0 != 0) {
                bytes memory seed = abi.encode(bh, packageId, i, 1);
                uint256 random = Util.randomUint(seed, 1, weight0 + weight1);

                if (random <= weight0) {
                    rar = rarity - 1;
                }
            }

            cardIdPres[i] =
                (cardType << 224) |
                (rar << 192) |
                (intialAmount << 128);
        }

        return cardIdPres;
    }

    function getRarityWeights(uint256 packageId)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 tokenAmount = uint256(uint64(packageId >> 160)).mul(1e18);

        uint256[] memory weights = new uint256[](6);

        if (tokenAmount <= rarityAmounts[0]) {
            weights[0] = 1;
        } else if (tokenAmount >= rarityAmounts[4]) {
            weights[4] = 999;
            weights[5] = 1;
        } else {
            uint256 rarity = 0;
            while (tokenAmount > rarityAmounts[rarity]) {
                rarity++;
            }

            if (tokenAmount == rarityAmounts[rarity]) {
                weights[rarity] = 1;
            } else {
                weights[rarity - 1] = rarityAmounts[rarity] - tokenAmount;
                weights[rarity] = tokenAmount - rarityAmounts[rarity - 1];
            }
        }

        return weights;
    }
}
