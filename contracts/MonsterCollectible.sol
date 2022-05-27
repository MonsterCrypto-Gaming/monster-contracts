// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;
    VRFCoordinatorV2Interface COORDINATOR;



    // Your subscription ID.
    uint64 private s_subscriptionId;

    // For networks, see https://docs.chain.link/docs/vrf-contracts/#configurations
    // address s_vrfCoordinator;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 private s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 private s_callbackGasLimit = 500000;

    // The default is 3, but you can set this higher.
    uint16 private s_requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 private s_numWords = 1;

    uint256[] private s_randomNumSplit;
    uint256[] private s_randomNum;
    uint256 public s_requestId;
    uint256 public s_splitBy = 4;
    address s_owner;
    address public deployer;

    //IN DEVELOPMENT//

    //GAME VARIABLES
    uint8 private MAX_TYPE = 15;
    struct MonsterReciept {
    address owner;
        mapping(address => uint) ownerToPackId;
        mapping(address => uint) ownerToPackQuantity;
        mapping(address => uint) ownerToMonsterType;
        mapping(address => uint) ownerToMonsterId;
        mapping(address => uint[]) randomNumbers;
    }
    MonsterReciept public monster;
    mapping(address => bool) public mintRights;
    mapping(uint => mapping(uint => uint)) private mintPacksCost;
    mapping(uint => uint) private mintPackQuantity;
    mapping(uint => uint) public tokenIdToMonster;

    string public baseMetadataURI; //metadata URI

    ERC20 LINK_token = ERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709); // rinekby
    mapping(uint256 => address) public sender_request_ids;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ReceiveRandomNumber(uint256[] numReceived);
    event SplitBy_Updated(uint256 newSplitBy);
    event MonsterGenerated(uint monsterId);
    event RandomNumberArray(uint[]);
    event openedPack(address owner, bool opened);

    error setSplitBy__NumberInvalid();

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) ERC721("MMO", "MFO") {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() private returns (uint256) {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        return s_requestId;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://bafybeifglhkoktbn7r7rvigkgaabh4wvu2rilavd74snwu7rzmza4yukce.ipfs.nftstorage.link/";
    }
    
    function contractURI() public view returns (string memory) {
        return "https://metadata-url.com/my-metadata";
    }

    function between(uint x, uint min, uint max) private pure returns (bool) {
        return x >= min && x <= max;
    }   

     function createMapping() public {
        mintPacksCost[1][3] = .01 ether;
        mintPacksCost[2][6] = .02 ether;
        mintPackQuantity[1] = 3;
        mintPackQuantity[2] = 6;
    }

    function mintPack(uint8 _mintPack) public payable {
        require(_mintPack == 1 || _mintPack == 2, "incorrect mint pack id");
        if (_mintPack == 1) {
            require(msg.value == mintPacksCost[_mintPack][3], "incorrect amount sent for packId");
        } else {
            require(msg.value == mintPacksCost[_mintPack][6], "incorrect amount sent for packId");
        }
        MonsterReciept storage monster_reciept = monster;
        monster_reciept.owner = msg.sender;
        monster_reciept.ownerToPackId[msg.sender] = _mintPack;
        monster_reciept.ownerToPackQuantity[msg.sender] = mintPackQuantity[_mintPack];
        sender_request_ids[requestRandomWords()] = msg.sender;
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

        
    function openPack() public payable {
        require(mintRights[msg.sender] == true, "buy a starter pack first");
        uint mLevel = getMonsterRarity(monster.randomNumbers[msg.sender][0]);
        uint mId = filterMonstersByRarity(mLevel, monster.randomNumbers[msg.sender][1]);
        safeMint(msg.sender, mId);
        emit openedPack(msg.sender, true);
        mintRights[msg.sender] = false;
    }

    function safeMint(address to, uint mId) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        string memory str = Strings.toString(mId);
        _setTokenURI(tokenId, string(abi.encodePacked(_baseURI(), str, ".json")));
        tokenIdToMonster[tokenId] = mId;
        emit MonsterGenerated(mId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        string memory str = Strings.toString(tokenIdToMonster[tokenId]);
        return string(abi.encodePacked(_baseURI(), str, ".json"));
    }


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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory _randomness
    ) internal override {
        MonsterReciept storage monster_reciept = monster;
        s_randomNum = _randomness;
        emit ReceiveRandomNumber(s_randomNum);
        s_randomNumSplit = expand(s_randomNum[0], s_splitBy); //4 diff numbas
        emit RandomNumberArray(s_randomNumSplit);
        monster_reciept.randomNumbers[sender_request_ids[requestId]] = s_randomNumSplit;
        mintRights[sender_request_ids[requestId]] = true;
    }
    
    function expand(uint256 num, uint256 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] =
                (uint256(keccak256(abi.encode(num, i))) % 100) +
                1;
        }
        return expandedValues;
    }

    function getCardRandomizerNumbers()
        external
        view
        returns (uint256[] memory)
    {
        return s_randomNumSplit;
    }

    function getCLRandomNumber() external view returns (uint256[] memory) {
        return s_randomNum;
    }

    function getSubscriptionId() external view onlyOwner returns (uint64) {
        return s_subscriptionId;
    }

    function setSplitBy(uint256 _newsplitby)
        external
        onlyOwner
        returns (uint256)
    {
        if (_newsplitby <= 0) {
            revert setSplitBy__NumberInvalid();
        }
        s_splitBy = _newsplitby;
        emit SplitBy_Updated(s_splitBy);
        return s_splitBy;
    }
}
