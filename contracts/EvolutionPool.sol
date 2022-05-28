// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./MonsterCollectible.sol";

/// @title Evolution Pool
/// @author Freddie71010
/// @notice This contract provides the ability to evolve your cards by supplying X number of duplicate cards and in exchange you receive a rarer card.

contract EvolutionPool is MonsterCollectible {
    
    uint256[] s_commonEvolve = [101, 104, 107];
    uint256[] s_rareEvolve = [102, 105, 108];
    uint256[] s_ultraRareEvolve = [103, 106, 109];
    bool s_allSameMonsterIds = false;
    bool s_correctQuantityOfMonsterCards = false;
    mapping(uint256 => uint256) public s_monsterIdToMonsterRarity;

    event MonsterToEvolve(address owner, uint256 cardQuantity, uint256 monsterToEvolveId, uint256 evolutionMonsterId);
    event BurnedMonsterIds(address owner, uint256[] burnedMonsterIds);

    constructor (
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) MonsterCollectible(_subscriptionId, _vrfCoordinator, _keyHash) {
        setMonsterMapperEvolutionPool();
    }

    // take in an array of IDs and verify 1) they are all the same and 2) user owns them
    function evolveMonster(uint256[] memory _monsterIds) public {
        s_allSameMonsterIds = false;
        s_correctQuantityOfMonsterCards = false;
        
        uint256 monsterToEvolveId = s_tokenIdToMonster[_monsterIds[0]];
                
        // check to make sure all IDs are the same monster
        for (uint i = 1; i < _monsterIds.length - 1; i++) {
            if (monsterToEvolveId != s_tokenIdToMonster[_monsterIds[i]]) {
                break;
            } else {
                s_allSameMonsterIds = true;
            }     
        }
        
        if (s_allSameMonsterIds != true){
            revert("Provided cards are not all the same Monster ID");
        } 
        
        // determine if this monster is common or rare
        uint256 rarityLevel = s_monsterIdToMonsterRarity[monsterToEvolveId];
        if (rarityLevel == 1 && _monsterIds.length == 20) {
            s_correctQuantityOfMonsterCards = true;
        } else if (rarityLevel == 2 && _monsterIds.length == 5) {
            s_correctQuantityOfMonsterCards = true;
        }

        if (s_correctQuantityOfMonsterCards != true){
            revert("Quantity of provided cards for evolution is incorrect.");
        }

        // make sure both bools are true
        if (s_correctQuantityOfMonsterCards == true && s_allSameMonsterIds == true) {
            uint256 evolveMonsterId = monsterToEvolveId + 1;
            emit MonsterToEvolve(msg.sender, _monsterIds.length, monsterToEvolveId, evolveMonsterId);
            
            burnMonsters(_monsterIds);
            mintMonster(evolveMonsterId, msg.sender);   // func from MonsterCollectible
        }
    }

    function burnMonsters(uint256[] memory _burnIds) internal {
        for (uint i = 0; i < _burnIds.length; i++) {
            _burn(_burnIds[i]);
        }
        emit BurnedMonsterIds(msg.sender, _burnIds);
    }

    function setMonsterMapperEvolutionPool() private {
        s_monsterIdToMonsterRarity[101]=1;
        s_monsterIdToMonsterRarity[102]=2;
        s_monsterIdToMonsterRarity[103]=3;
        s_monsterIdToMonsterRarity[104]=1;
        s_monsterIdToMonsterRarity[105]=2;
        s_monsterIdToMonsterRarity[106]=3;
        s_monsterIdToMonsterRarity[107]=1;
        s_monsterIdToMonsterRarity[108]=2;
        s_monsterIdToMonsterRarity[109]=3;
        s_monsterIdToMonsterRarity[110]=2;
        s_monsterIdToMonsterRarity[111]=2;
        s_monsterIdToMonsterRarity[112]=3;
        s_monsterIdToMonsterRarity[113]=1;
        s_monsterIdToMonsterRarity[114]=1;
        s_monsterIdToMonsterRarity[115]=1;
    }
}
