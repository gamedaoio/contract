pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: SimPL-2.0

import "../ContractOwner.sol";
import "../shop/Shop.sol";

contract Airdrop is Shop {
    constructor() {}

    uint256[] public rarityWeights;
    uint256 public rarityWeightTotal;

    function airdrop(
        address[] memory tos,
        uint256[] memory tokenAmounts,
        uint256[] memory rarities
    ) external CheckPermit("Config") {
        uint256 length = tos.length;

        for (uint256 i = 0; i != length; ++i) {
            _buy(tos[i], address(0), tokenAmounts[i], 1, rarities[i]);
        }
    }

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

    function onOpenPackage(
        address,
        uint256 packageId,
        bytes32 bh
    ) external view override returns (uint256[] memory) {
        uint256 amount = uint64(packageId >> 160);
        uint256 quantity = uint16(packageId >> 144);
        uint256 rarity = uint16(packageId >> 104);

        uint256[] memory cardIdPres = new uint256[](quantity);

        for (uint256 i = 0; i != quantity; ++i) {
            uint256 cardType = calcCardType(abi.encode(bh, packageId, i));
            // uint256 rarity = Util.RARITY_ORANGE;

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
