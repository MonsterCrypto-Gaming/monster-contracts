// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFv2Consumer.sol";

/// @title MonsterShop ERC-1155 Contract
/// @author Freddie71010
/// @notice This contract provides the ability to mint a pack of "Monster" cards - w/ Chainlink VRF and decentralized storage

contract MonsterCollectible2 is ERC721URIStorage, Ownable, Pausable, VRFv2Consumer {
    using Counters for Counters.Counter;
    // address s_owner;

    // NFT
    uint8 constant public STARTER_PACK = 2;
    uint256 constant public STARTER_PACK_FEE = 0.015 ether;
    // string[15] internal s_monsterTokenURIs;
    Counters.Counter public tokenIdCounter;
    
    // VRF Helpers
    // VRFv2Consumer immutable i_vrfCoordinator;
    mapping(uint256 => address) public s_requestIdToSender;
    // string public baseMetadataURI; //metadata URI

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(address owner, uint256 uniqueNftTokenId, uint256 monsterId);
    event MonsterToGenerate(uint256 _monsterUniqueId);
    
    error MonsterId__NumberInvalid();

    // =====================================================================================
    constructor (
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    )
    VRFv2Consumer(_subscriptionId, _vrfCoordinator, _keyHash)
    ERC721("Monstermons", "MON") {}

    // Main function 1 - Gets Random Numbers from CL to be used for Monster selection and generation
    function requestBoosterPack() public {
        requestRandomWords(); 
        s_requestIdToSender[s_requestId] = msg.sender;

    }
    
    // Main function 2 - Selects monsters to be generated and mints monsters
    function mintBoosterPack() public {
        (
            uint256 monster1RarityInput,
            uint256 monster1SpecificInput,
            , // uint256 monster2RarityInput,
             // uint256 monster2SpecificInput
        ) = _splitInto4Numbers(s_monsterGeneratorNums);

        uint256 monster1Id = generateMonster(monster1RarityInput, monster1SpecificInput); // returns Monster ID
        // generateMonster(monster2RarityInput, monster2SpecificInput);
        
        // now it's time to mint monster
        address monsterOwner = s_requestIdToSender[s_requestId];
        uint256 newTokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        _safeMint(monsterOwner, newTokenId);
        // set the tokenURI of Monster
        string memory strMonster1Id = Strings.toString(monster1Id);
        _setTokenURI(newTokenId, string(abi.encodePacked(_baseURI(), strMonster1Id, ".json")));
        
        emit NftMinted(monsterOwner, newTokenId, monster1Id);
    }
    
    function _splitInto4Numbers(uint256[] memory _nums) internal pure returns (uint256, uint256, uint256, uint256) {
        return (
            _nums[0],
            _nums[1],
            _nums[2],
            _nums[3]
        );
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "https://bafybeifglhkoktbn7r7rvigkgaabh4wvu2rilavd74snwu7rzmza4yukce.ipfs.nftstorage.link/";
    }

    

    function generateMonster(uint256 _rarityNumInput, uint256 _specificMonsterInput) internal returns (uint256) {
        uint256 monsterRarity = getMonsterRarity(_rarityNumInput);
        uint256 monsterId = filterMonstersByRarity(monsterRarity, _specificMonsterInput);
        if (true != between(monsterId, 101, 115)) {
            revert MonsterId__NumberInvalid();
        }
        emit MonsterToGenerate(monsterId);
        return monsterId;
    }

    // //withdrawing contract balances
    // function withdraw() public {
    //     payable(s_owner).transfer(address(this).balance);
    //     LINK_token.transfer(payable(s_owner), LINK_token.balanceOf(address(this)));
    //     //LINK_ERC677_token.transfer(payable(s_owner), LINK_ERC677_token.balanceOf(address(this)));
    // }

    // ================================================================================================
    
    function filterMonstersByRarity(uint256 _rarity, uint256 _specificMonsterInput) private pure returns (uint256) {
        uint256 monId;
        require((_rarity <= 3 && _rarity >= 1), "incorrect value sent, Rarity Level should be 1, 2 or 3");
        if (_rarity == 1) {
            monId = getCommonMonster(_specificMonsterInput);
        } else if (_rarity == 2) {
            monId = getRareMonster(_specificMonsterInput);
        } else {
            monId = getUltraRareMonster(_specificMonsterInput);
        }
        return monId;
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
