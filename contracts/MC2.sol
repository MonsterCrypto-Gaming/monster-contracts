// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink-brownie/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFv2Consumer.sol";

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
    // address s_owner; = this is currently declared in VRFv2Consumer
    string public baseMetadataURI; //metadata URI

    ERC20 LINK_token = ERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709); // rinekby

    // mapping() public s_rarityBreakdown;
    mapping(address => uint256) public s_accountToTokenDeposits;

    mapping(uint => string)[16] public monster_almanac;
    // monster_almanac[11] = "Monster #1";
    // monster_almanac[12] = "Monster #2";
    
    event MonsterToGenerate(uint256 _monsterUniqueId);
    
    error MonsterId__NumberInvalid();


    function mintMonsters() internal {
        (
            uint256 monster1RarityInput,
            uint256 monster1SpecificInput,
            uint256 monster2RarityInput,
            uint256 monster2SpecificInput,

        ) = VRFv2Consumer.getCardRandomizerNumbers();

        // use monster1RarityInput to look up mapping for rarity level
        // then use monster1SpecificInput to look up mapping for specific monster based on the rarity level
        // now you have one specific set of metadata
        generateMonster(monster1RarityInput, monster1SpecificInput);
        generateMonster(monster2RarityInput, monster2SpecificInput);

        //_mint();
    }

    function generateMonster(uint256 _rarityNumInput, uint256 _specificMonsterInput) internal {
        uint256 monsterRarity = getMonsterRarity(_rarityNumInput);
        uint256 monsterId = filterMonstersByRarity(monsterRarity, _specificMonsterInput);
        if (true != between(monsterId, 101, 115)) {
            revert MonsterId__NumberInvalid();
        }
        emit MonsterToGenerate(monsterId);
        createMonsterNFT(monsterId);
    }

    function createMonsterNFT(uint256 _monsterId) private {
        // use _monsterId to reference the metadata files to generate NFT
        // EX: _monsterId = 104
        // Inside 'metadata' folder we will have a file called '104.json' which contains all the NFT metadata for that Monster
    }
    
    //withdrawing contract balances
    function withdraw() public {
        payable(s_owner).transfer(address(this).balance);
        LINK_token.transfer(payable(s_owner), LINK_token.balanceOf(address(this)));
        //LINK_ERC677_token.transfer(payable(s_owner), LINK_ERC677_token.balanceOf(address(this)));
    }

    function filterMonstersByRarity(uint256 _rarity, uint256 _specificMonsterInput) private returns (uint256) {
        uint256 monsterId;
        require((_rarity <= 3 && _rarity >= 1), "incorrect value sent, Rarity Level should be 1, 2 or 3");
        if (_rarity == 1) {
            monsterId = getCommonMonster(_specificMonsterInput);
        } else if (_rarity == 2) {
            monsterId = getRareMonster(_specificMonsterInput);
        } else {
            monsterId = getUltraRareMonster(_specificMonsterInput);
        }
    }

    function between(uint256 x, uint256 min, uint256 max) private pure returns (bool) {
        return x >= min && x <= max;
    }

    function getMonsterRarity(uint256 _number) private pure returns (uint256){
        uint256 monsterRarity;
        require((_number <= 100 && _number >= 1), "incorrect value sent, digit should be in 0-100 range");
        if (_number <= 59) {
            monsterRarity = 1;
        } else if (_number > 59 && _number <= 84) {
            monsterRarity = 2;
        } else {
            monsterRarity = 3;
        }
        return monsterRarity;
    }

    function getCommonMonster(uint256 _number) private pure returns (uint256) {
        uint256 monsterId;
        require((_number <= 100 && _number >= 1), "incorrect value sent, digit should be in 1-100 range");
        if (between(_number, 1, 17)) {
            monsterId = 101;
        } else if (between(_number, 18, 34)) {
            monsterId = 104;
        } else if (between(_number, 35, 51)) {
            monsterId = 107;
        } else if (between(_number, 52, 68)) {
            monsterId = 113;
        } else if (between(_number, 69, 84)) {
            monsterId = 114;
        } else {
            monsterId = 115;
        }
        return monsterId;
    }

    function getRareMonster(uint256 _number) private pure returns (uint256) {
        uint256 monsterId;
        require((_number <= 100 && _number >= 1), "incorrect value sent, digit should be in 1-100 range");
        if (between(_number, 1, 50)) {
            monsterId = 110;
        } else {
            monsterId = 111;
        }
        return monsterId;
    }

    function getUltraRareMonster(uint256 _number) private pure returns (uint256) {
        uint256 monsterId;
        require((_number <= 100 && _number >= 1), "incorrect value sent, digit should be in 1-100 range");
        monsterId = 112;
        return monsterId;
    }
}
