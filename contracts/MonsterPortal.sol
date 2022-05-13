// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title MonsterShop ERC-1155 Contract
/// @author 0xCrispy
/// @notice This contract provides the ability to mint a pack of "Monster" cards - w/ Chainlink VRF and decentralized storage

contract MonsterShop is ERC1155, Ownable, Pausable, VRFConsumerBase {

    //IN DEVELOPMENT//

    //GAME VARIABLES
    uint8 private lvl1 = 1; // Common
    uint8 private lvl2 = 2; // Rare
    uint8 private lvl3 = 3; // UltraRare

    //NFT Mint Fee
    uint256 public mintFee = 0.1 ether;
    uint8 public MAX_SUPPLY = 60;
    
    //Chainlink VRF Stuff
    bytes32 public VRF_KEYHASH = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint256 public VRF_FEE = 0.01 ether; 
    address public VRF_COORDINATOR = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    
    address public deployer = 0x0000000000000000000000000000000000000000;
    
    //Import Interfaces
    ERC20 WMATIC_token  = ERC20(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    ERC20 LINK_token  = ERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    ERC20 LINK_ERC677_token  = ERC20(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
    AggregatorV3Interface MATIC_LINK_price_feed = AggregatorV3Interface(0x5787BefDc0ECd210Dfa948264631CD53E68F7802);

    mapping(bytes32  => address) public sender_request_ids;

    constructor()
        ERC1155("https://METADATA/{id}.json")
        VRFConsumerBase(
            VRF_COORDINATOR,
            address(LINK_token)
        )
    {
    }

    function mintPack(address to) public payable
    {
        require(msg.value >= mintFee, "incorrect amount sent");
        sender_request_ids[requestRandomness(VRF_KEYHASH, VRF_FEE)] = to;
    }

    //chainlink call
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint token_id = randomness % 2 + 1;
        uint amount = 1;
        _mint(sender_request_ids[requestId], token_id, amount, "");
    }

    //withdrawing contract balances
    function withdraw() public
    {
        payable(deployer).transfer(address(this).balance);
        LINK_token.transfer(payable(deployer), LINK_token.balanceOf(address(this)));
        LINK_ERC677_token.transfer(payable(deployer), LINK_ERC677_token.balanceOf(address(this)));
    }

    //emergency stuff
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
