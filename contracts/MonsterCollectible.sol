// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink-brownie/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink-brownie/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title MonsterShop ERC-1155 Contract
/// @author 0xCrispy
/// @notice This contract provides the ability to mint a pack of "Monster" cards - w/ Chainlink VRF and decentralized storage

contract MonsterCollectible is ERC1155, Ownable, Pausable, VRFConsumerBase {
    //IN DEVELOPMENT//

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

    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        fee = _fee;
        keyHash = _keyHash;
    }

    constructor(string memory _name)
        ERC1155(
            "https://bafybeigrfsyjsgjcapbehtpfttm3z5arfs6amwo2ni4nz2pgcs65fb65di.ipfs.nftstorage.link/{id}.json"
        ) //test meta
        VRFConsumerBase(vrfCoordinator, address(LINK_token))
    {
        deployer = address(msg.sender);
        name = _name;
    }

    function mintPack(uint8 _mintPack) public payable {
        uint256 mintFee;
        require(_mintPack == 1 || _mintPack == 2, "incorrect mint pack id");
        if (_mintPack == 1) {
            mintFee = starterPackFee;
        } else {
            mintFee = proPackFee;
        }
        require(msg.value >= mintFee, "incorrect amount sent");
        sender_request_ids[requestRandomness(vrfKeyHash, vrfFee)] = address(
            msg.sender
        );
    }

    //chainlink call
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 token_id = (randomness % MAX_SUPPLY) + 1;
        uint256 amount = 1;
        _mint(sender_request_ids[requestId], token_id, amount, "");
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
