// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title MonsterShop ERC-1155 Contract
/// @author Freddie71010
/// @notice This contract provides the ability to mint a pack of "Monster" cards - w/ Chainlink VRF and decentralized storage

contract MonsterCollectible2 is ERC1155, Ownable, Pausable, VRFv2Consumer {
    //GAME VARIABLES
    uint8 private lvl1 = 1; // Common
    uint8 private lvl2 = 2; // Rare
    uint8 private lvl3 = 3; // UltraRare

    //MINT PACKS
    uint8 public starterPack = 2;
    // uint8 public proPack = 3;

    //NFT Mint Fee
    uint256 public starterPackFee = 0.015 ether;
    // uint256 public proPackFee = 0.020 ether;

    uint256[] public ids; //uint array of ids
    string public baseMetadataURI; //metadata URI
    string public name; //token mame

    function mintMonsters() {
        (
            monster1Rarity,
            monster1Specific,
            monster2Rarity,
            monster2Specific,

        ) = VRFv2Consumer.getCardRandomizerNumbers();

        // use monster1Rarity to look up mapping for rarity level
        // then use monster1Specific to look up mapping for specific monster based on the rarity level
        // now you have one specific set of metadata
    }
}
