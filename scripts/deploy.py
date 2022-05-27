from brownie import MonsterCollectible, VRFv2Consumer, MonsterToken, config, network
from .utils import get_account, print_line, wait_for_randomness, listen_for_event
import time, sys


def deploy_monster_token():
    account = get_account()
    monster_token = MonsterToken.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print_line("Deployed Monster ($MON) tokens!")
    return monster_token

def deploy_monster_collectible():
    account = get_account(env="MM1")
    monster_collectible = MonsterCollectible.deploy(
        config["networks"][network.show_active()]["subscription_id"],
        config["networks"][network.show_active()]["vrfcoordinator"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", True),
    )
    print_line("Deployed Monster Collectible!")
    print("")
    print_line("WARNING", char="*")
    print_line("MAKE SURE YOU ADD NEWLY DEPLOYED CONTRACT TO CHAINLINK SUBSCRIPTION - https://vrf.chain.link/", char="*")
    input("Add address as a 'Consumer' to VRF Chainlink Manager to continue. Push 'Enter' when ready:")
    return monster_collectible

def buy_booster_pack():
    account = get_account(env="MM1")
    monster_collectible = MonsterCollectible[-1]
    print_line(f"MonsterCollectible contract address: {monster_collectible.address}")
    starting_tx = monster_collectible.buyBoosterPack({"from": account, "amount": 10000000000000000})    # 0.01 eth
    starting_tx.wait(1)
    print_line("buyBoosterPack has started!")
    event = listen_for_event(
        monster_collectible, "MonsterGeneratorNums", timeout=5*60, poll_interval=20
    )
    print(event)

def open_booster_pack():
    account = get_account(env="MM1")
    monster_collectible = MonsterCollectible[-1]
    print_line(f"MonsterCollectible contract address: {monster_collectible.address}")
    starting_tx = monster_collectible.openBoosterPack({"from": account})
    starting_tx.wait(1)
    print_line("openBoosterPack has started!")
    # TODO: Fix this 'NftMinted' event as it's not working!
    # event = listen_for_event(
    #     monster_collectible, "NftMinted", timeout=1*60, poll_interval=10
    # )
    # print(event)
    

def deploy_vrfv2consumer():
    account = get_account(env="MM1")
    # Assumes the subscription is funded sufficiently.
    vrfv2consumer = VRFv2Consumer.deploy(
        config["networks"][network.show_active()]["subscription_id"],
        config["networks"][network.show_active()]["vrfcoordinator"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", True),
    )
    print_line("Deployed VRFv2Consumer")
    
def request_random_nums():
    account = get_account(env="MM1")
    vrfv2consumer = VRFv2Consumer[-1]
    print_line("MAKE SURE YOU ADD NEWLY DEPLOYED CONTRACT TO CHAINLINK SUBSCRIPTION - https://vrf.chain.link/rinkeby/4552")
    vrfv2consumer.requestRandomWords({"from": account})
    wait_for_randomness(vrfv2consumer)
    card_randomizer_nums = vrfv2consumer.getCardRandomizerNumbers({"from": account})
    print(f"card_randomizer_nums: {card_randomizer_nums}")



def main():
    '''
    Use below command to run specific function from deploy script:
    `brownie run scripts/deploy.py <FUNC_NAME>`
    EX: brownie run scripts/deploy.py buy_booster_pack --network rinkeby
    '''
    # deploy_monster_token()
    # deploy_vrfv2consumer()
    # request_random_nums()
    deploy_monster_collectible()
    buy_booster_pack()
    open_booster_pack()
    print("done")