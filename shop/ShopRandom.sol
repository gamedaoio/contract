pragma solidity ^0.7.0;

// SPDX-License-Identifier: SimPL-2.0

import "../lib/Util.sol";

import "./Shop.sol";

abstract contract ShopRandom is Shop {
    uint256[] public rarityWeights;
    uint256 public rarityWeightTotal;

    uint256 public price;

    uint256 public tokenAmount;

    function setRarityWeights(uint256[] memory weights)
        external
        CheckPermit("Config")
    {
        rarityWeights = weights;

        uint256 total = 0;
        uint256 length = weights.length;

        for (uint256 i = 0; i != length; ++i) {
            total += weights[i];
        }
        rarityWeightTotal = total;
    }

    function setPrice(uint256 _price) external CheckPermit("Config") {
        price = _price;
    }

    function setTokenAmount(uint256 amount) external CheckPermit("Config") {
        tokenAmount = amount;
    }

    function _buyRandom(uint256 quantity, uint256 padding) internal {
        _buy(msg.sender, address(0), tokenAmount, quantity, padding);
    }

    function onOpenPackage(
        address,
        uint256 packageId,
        bytes32 bh
    ) external view override returns (uint256[] memory) {
        uint256 amount = uint64(packageId >> 160);
        uint256 quantity = uint16(packageId >> 144);

        uint256[] memory cardIdPres = new uint256[](quantity);

        for (uint256 i = 0; i != quantity; ++i) {
            uint256 cardType = calcCardType(abi.encode(bh, packageId, i));
            uint256 rarity =
                Util.randomWeight(
                    abi.encode(bh, packageId, i, 1),
                    rarityWeights,
                    rarityWeightTotal
                );

            cardIdPres[i] =
                (cardType << 224) |
                (rarity << 192) |
                (amount << 128);
        }

        return cardIdPres;
    }

    function getRarityWeights(uint256)
        external
        view
        override
        returns (uint256[] memory)
    {
        return rarityWeights;
    }
}
