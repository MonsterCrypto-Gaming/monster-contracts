from brownie import MonsterCollectible2, VRFv2Consumer, MonsterToken, config, network
from .utils import get_account, print_line, wait_for_randomness
import time


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
    monster_collectible = MonsterCollectible2.deploy(
        config["networks"][network.show_active()]["subscription_id"],
        config["networks"][network.show_active()]["vrfcoordinator"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", True),
    )
    print_line("Deployed Monster Collectible!")
    return monster_collectible

def request_booster_pack():
    account = get_account(env="MM1")
    monster_collectible = MonsterCollectible2[-1]
    print_line(f"MonsterCollectible contract address: {monster_collectible.address}")
    starting_tx = monster_collectible.RequestBoosterPack({"from": account})
    starting_tx.wait(1)
    print_line("Mint Booster Pack has started!")

def mint_booster_pack():
    account = get_account(env="MM1")
    monster_collectible = MonsterCollectible2[-1]
    print_line(f"MonsterCollectible contract address: {monster_collectible.address}")
    starting_tx = monster_collectible.mintBoosterPack({"from": account})
    starting_tx.wait(1)
    print_line("Mint Booster Pack has started!")


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
    # deploy_monster_token()
    # deploy_vrfv2consumer()
    # request_random_nums()
    # deploy_monster_collectible()
    # request_booster_pack()
    # mint_booster_pack()
    print("done")
