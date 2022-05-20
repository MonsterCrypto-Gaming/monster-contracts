// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2Consumer is VRFConsumerBaseV2 {
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
    uint32 private s_callbackGasLimit = 200000;

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

    event ReceiveRandomNumber(uint256[] numReceived);
    event NewlySplitNumbers(uint256[] numToSplit);
    event SplitBy_Updated(uint256 newSplitBy);

    error setSplitBy__NumberInvalid();

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = _subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory _randomness
    ) internal override {
        s_randomNum = _randomness;
        emit ReceiveRandomNumber(s_randomNum);
        s_randomNumSplit = expand(s_randomNum[0], s_splitBy);
        emit NewlySplitNumbers(s_randomNumSplit);
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

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
