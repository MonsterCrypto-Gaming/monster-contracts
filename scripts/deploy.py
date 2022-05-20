from tracemalloc import start
from brownie import VRFv2Consumer, MONToken, MonsterCollectible, accounts, config, network
from .utils import get_account, LOCAL_BLOCKCHAIN_ENVS, get_contract, fund_with_link, print_line
import time


def deploy_monster_token():
    account = get_account()
    monster_token = MONToken.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print_line("Deployed Monster ($MON) tokens!")
    return monster_token

def deploy_monster_collectible():
    account = get_account()
    monster_collectible = MonsterCollectible.deploy(
        get_contract("vrfcoordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["fee"],
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print_line("Deployed Monster Collectible!")
    return monster_collectible

def deploy_vrfv2consumer():
    account = get_account(brownie_id='MetaMask_TEST_WALLET')
    # Assumes the subscription is funded sufficiently.
    vrfv2consumer = VRFv2Consumer.deploy(
        config["networks"][network.show_active()]["subscription_id"],
        get_contract("vrfcoordinator").address,
        config["networks"][network.show_active()]["keyhash"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", True),
    )
    print_line("Deployed VRFv2Consumer")
    tx_requestrandomness = vrfv2consumer.requestRandomWords()
    tx_requestrandomness.wait(3)
    time.sleep(60)
    card_randomizer_nums = vrfv2consumer.getCardRandomizerNumbers()
    print(f"card_randomizer_nums: {card_randomizer_nums}")



def main():
    # deploy_monster_token()
    # deploy_monster_collectible()
    deploy_vrfv2consumer()
