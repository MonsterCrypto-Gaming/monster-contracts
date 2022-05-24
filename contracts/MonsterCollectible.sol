// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title MonsterShop ERC-1155 Contract
/// @author 0xCrispy
/// @notice This contract provides the ability to mint a pack of "Monster" cards - w/ Chainlink VRF and decentralized storage

contract MonsterCollectible is ERC1155, Ownable, Pausable, VRFConsumerBase {
    //IN DEVELOPMENT//

    //GAME VARIABLES
    uint8 private MAX_TYPE = 15;
    struct MonsterReciept {
        address owner;
        mapping(address => uint) ownerToPackId;
        mapping(address => uint) ownerToPackQuantity;
    }
    MonsterReciept public monster;
    mapping(uint => mapping(uint => uint)) mintPacksCost;
    mapping(uint => uint) mintPackQuantity;
    //mapping(uint => mapping(uint => uint)) monsterLevels;

    uint256[] public ids; //uint array of ids
    string public baseMetadataURI; //metadata URI
    string public name; //token mame
    uint public testChainlink;
    

    //Chainlink VRF Stuff
    bytes32 public vrfKeyHash =
        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; // rinekby
    uint256 public vrfFee = 0.25 * 10**18; //0.25 LINK
    address public vrfCoordinator = 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B; // rinekby

    address public deployer;
    ERC20 LINK_token = ERC20(0x01BE23585060835E02B77ef475b0Cc51aA1e0709); // rinekby
    mapping(bytes32 => address) public sender_request_ids;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // TODO list:
    // User goes to Shop to buy a booster = mints two NFTs
    // parsing _randomness to generate specifics on which Monster NFT to mint

    uint256 public fee;
    bytes32 public keyHash;
    address payable public recentWinner;
    uint256 public randomNum;

    /*
    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        fee = _fee;
        keyHash = _keyHash;
    }
    */

    
    constructor(string memory _name)
        ERC1155(
            "https://bafybeigrfsyjsgjcapbehtpfttm3z5arfs6amwo2ni4nz2pgcs65fb65di.ipfs.nftstorage.link/{id}.json"
        ) 
        VRFConsumerBase(vrfCoordinator, address(LINK_token))
    {
        deployer = address(msg.sender);
        name = _name;
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
        sender_request_ids[requestRandomness(vrfKeyHash, vrfFee)] = address(msg.sender);
    }

    //chainlink call
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint tokenId = randomness % (10000000 % 99999999);
        _mint(sender_request_ids[requestId], tokenId, 1, "");

    }


    function getType(uint _num) {
        if (_num <= 59) {

        } else if (_num > 59 <= 84) {

        } else {
            
        }
    }

    //withdrawing contract balances
    function withdraw() public {
        payable(deployer).transfer(address(this).balance);
        LINK_token.transfer(
            payable(deployer),
            LINK_token.balanceOf(address(this))
        );
        //LINK_ERC677_token.transfer(payable(deployer), LINK_ERC677_token.balanceOf(address(this)));
    }

    /*
    sets our URI and makes the ERC1155 OpenSea compatible
    */
    function uri(uint256 _tokenid)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseMetadataURI,
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /*
    used to change metadata, only owner access
    */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    //emergency stuff
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
