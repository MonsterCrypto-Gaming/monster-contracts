from tracemalloc import start
from brownie import MonsterPortal, accounts, config, network
from .utils import get_account, LOCAL_BLOCKCHAIN_ENVS, get_contract, fund_with_link, print_line
import time


def deploy_monsterportal():
    account = get_account()
    monster_portal = MonsterPortal.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print_line("Deployed MonsterPortal!")
    return monster_portal

def main():
    deploy_monsterportal()


    
