from tracemalloc import start
from brownie import MONToken, MonsterPortal, accounts, config, network
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

def deploy_monsterportal():
    account = get_account()
    monster_portal = MonsterPortal.deploy(
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False),
    )
    print_line("Deployed MonsterPortal!")
    return monster_portal

def main():
    # deploy_monster_token()
    deploy_monsterportal()


    
