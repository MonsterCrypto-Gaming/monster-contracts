// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFv2Consumer.sol";

/// @title Monster Collectible
/// @author Freddie71010, 0xCrispy
/// @notice This contract provides the ability to mint a pack of "Monster" cards - w/ Chainlink VRF and decentralized storage

contract MonsterCollectible is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable, VRFv2Consumer {
    using Counters for Counters.Counter;

    // NFT
    uint8 constant public STARTER_PACK = 2;
    uint256 constant public STARTER_PACK_FEE = 0.01 ether;
    Counters.Counter private tokenIdCounter;
    mapping(uint256 => string) public monsterIdToMonsterName;
    
    //GAME VARIABLES
    // struct MonsterReceipt {
    //     address owner;
    //     mapping(address => uint) ownerToPackId;
    //     mapping(address => uint) ownerToPackQuantity;
    //     mapping(address => uint) ownerToMonsterType;
    //     mapping(address => uint) ownerToMonsterId;
    //     mapping(address => uint[]) randomNumbers;
    // }
    // MonsterReceipt public monster;
    // mapping(address => bool) public mintRights;
    // mapping(uint => mapping(uint => uint)) private mintPacksCost;
    // mapping(uint => uint) private mintPackQuantity;
    mapping(address => uint) public s_addressToUnmintedPacks; // Address -to- Number of unminted pack in wallet
    mapping(uint => uint) public s_tokenIdToMonster; // Unique NFT Token ID -to- Monster ID
    
    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(address owner, uint256 uniqueNftTokenId, uint256 monsterId, string monsterName);
    
    // Errors
    error MonsterId__NumberInvalid();

    // =====================================================================================
    constructor (
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    )
    VRFv2Consumer(_subscriptionId, _vrfCoordinator, _keyHash)
    ERC721("Monster Forest", "MON") {
        setMonsterMapper();
    }

    // Main function 1 - Gets Random Numbers from CL to be used for Monster selection and generation
    function buyBoosterPack() public payable {
        require(s_addressToUnmintedPacks[msg.sender] == 0, "User has unminted packs available to open. Open packs before purchasing another.");
        require(msg.value == STARTER_PACK_FEE, "Incorrect amount sent. Please send 0.01 ETH.");

        requestRandomWords(); 
        s_requestIdToSender[s_requestId] = msg.sender;
        s_addressToUnmintedPacks[msg.sender] = 1;
    }
    
    // Main function 2 - Selects monsters to be generated and mints monsters
    function openBoosterPack() public {
        require(s_addressToUnmintedPacks[msg.sender] == 1, "User has no booster packs available to open. Purchase a booster pack before proceeding.");
        (
            uint256 monster1RarityInput,
            uint256 monster1SpecificInput,
            uint256 monster2RarityInput,
            uint256 monster2SpecificInput
        ) = _splitInto4Numbers(s_monsterGeneratorNums);

        uint256 monster1Id = generateMonster(monster1RarityInput, monster1SpecificInput);
        uint256 monster2Id = generateMonster(monster2RarityInput, monster2SpecificInput);
        
        address monsterOwner = s_requestIdToSender[s_requestId];
        // Mint monsters
        mintMonster(monster1Id, monsterOwner);
        mintMonster(monster2Id, monsterOwner);
        
        s_addressToUnmintedPacks[msg.sender] = 0;
    }
    
    function mintMonster(uint256 _monster, address _monsterOwner) private {
        uint256 newTokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _safeMint(_monsterOwner, newTokenId);
        string memory strMonsterId = Strings.toString(_monster);
        _setTokenURI(newTokenId, string(abi.encodePacked(strMonsterId, ".json")));
        s_tokenIdToMonster[newTokenId] = _monster;
        emit NftMinted(_monsterOwner, newTokenId, _monster, monsterIdToMonsterName[_monster]);
    }
    
    function _splitInto4Numbers(uint256[] memory _nums) private pure returns (uint256, uint256, uint256, uint256) {
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

    function generateMonster(uint256 _rarityNumInput, uint256 _specificMonsterInput) private pure returns (uint256) {
        uint256 monsterRarity = getMonsterRarity(_rarityNumInput);
        uint256 monsterId = filterMonstersByRarity(monsterRarity, _specificMonsterInput);
        if (true != between(monsterId, 101, 115)) {
            revert MonsterId__NumberInvalid();
        }
        return monsterId;
    }

    // withdrawing contract balances
    function withdraw(address _to) public onlyOwner {
        require(address(this).balance > 0, "Balance of contract is 0");
        payable(_to).transfer(address(this).balance);
    }

    
    function setMonsterMapper() private {
        monsterIdToMonsterName[101]="Greenip";
        monsterIdToMonsterName[102]="Bloonip";
        monsterIdToMonsterName[103]="Trapnip";
        monsterIdToMonsterName[104]="Lavanoob";
        monsterIdToMonsterName[105]="Lapro";
        monsterIdToMonsterName[106]="Champlava";
        monsterIdToMonsterName[107]="Rabikid";
        monsterIdToMonsterName[108]="Ratrapa";
        monsterIdToMonsterName[109]="Rabuddaa";
        monsterIdToMonsterName[110]="Borodillo";
        monsterIdToMonsterName[111]="Electrazaar";
        monsterIdToMonsterName[112]="Mythikos";
        monsterIdToMonsterName[113]="Slitex";
        monsterIdToMonsterName[114]="Flyfury";
        monsterIdToMonsterName[115]="Terapartor";
    }
    // Helper functions for Monster generation calculation
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

    // ================================================================================================
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
