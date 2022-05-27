from brownie import (
    network,
    accounts,
    config,
    chain,
    web3,
    Contract,
    # MockV3Aggregator,
    # VRFCoordinatorMock,
    # LinkToken,
)
import requests
import time

DECIMALS = 8
STARTING_PRICE = 200_000_000_000  # == 2000e8 == 2,000
LOCAL_BLOCKCHAIN_ENVS = ["development", "ganache-local"]
FORKED_LOCAL_ENVS = ["mainnet-fork", "mainnet-fork-dev"]
# contract_to_mock = {
#     "eth_usd_price_feed": MockV3Aggregator,
#     "vrfcoordinator": VRFCoordinatorMock,
#     "link_token": LinkToken,
# }


def print_line(string, length=100, char='='):
    print(f"{string} {(length-len(string))*char}")

def get_account(index=None, brownie_id=None, env=None):
    # Gets acc from pre-configured Brownie accs based on the passed index
    if index:
        return accounts[index]
    # Gets acc from Brownie's list of accs based on passed ID
    if brownie_id:
        return accounts.load(brownie_id)
    # Gets acc from the passed private key env
    if env:
        accounts.add(config["wallets"][env])
    # Gets the first acc from pre-configured Brownie accs while on a local or forked blockchain
    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVS
        or network.show_active() in FORKED_LOCAL_ENVS
    ):
        return accounts[0]
    # Gets the first private key acc from env variables when on a mainnet/testnet
    return accounts.add(config["wallets"]["MM1"])


# def get_contract(contract_name):
#     """
#     If on a local network, deploy a mock contract and return that contract.
#     If on a mainnet/testnet network, return the deployed the contract.

#         Args:
#             contract_name (string)

#         Returns:
#             brownie.network.contract.ProjectContract: the most recently deployed version of the contract
#     """
#     contract_type = contract_to_mock[contract_name]

#     # Local Blockchains
#     if network.show_active() in LOCAL_BLOCKCHAIN_ENVS:
#         if len(contract_type) <= 0:
#             print("WIP deploy_mocks(). Now exiting.")
#             # deploy_mocks()
#         contract = contract_type[-1]
#     # Mainnet/Testnet Blockchains
#     else:
#         contract_address = config["networks"][network.show_active()][contract_name]
#         contract = Contract.from_abi(
#             contract_type._name, contract_address, contract_type.abi
#         )
#     return contract


# def deploy_mocks(decimals=DECIMALS, initial_value=STARTING_PRICE):
#     print_line(f"The active network is {network.show_active()}", char='-')
#     print_line("Deploying mocks...", char='-')
#     MockV3Aggregator.deploy(
#         decimals,
#         initial_value,
#         {"from": get_account()},
#     )
#     link_token = LinkToken.deploy({"from": get_account()})
#     VRFCoordinatorMock.deploy(link_token.address, {"from": get_account()})
#     print_line("Mocks deployed!", char='-')


# def fund_with_link(contract_address, account=None, link_token=None, amount=100000000000000000):  # 0.1 Link
#     account = account if account else get_account()
#     link_token = link_token if link_token else get_contract("link_token")
#     tx = link_token.transfer(contract_address, amount, {"from": account})
#     # link_token_contract = interface.LinkTokenInterface(link_token.address)  # interface
#     # tx = link_token_contract.transfer(contract_address, amount, {"from": account})
#     tx.wait(1)
#     print_line("Fund contract with LINK complete!")
#     return tx

def wait_for_randomness(contract):
    # Keeps checking for a RandomWordsRequested callback using the block explorer's API, and returns the randomness

    # Initial frequency, in seconds
    sleep_time = 120
    # Last checked block num
    from_block = len(chain)
    print("Waiting For Data...")
    print(f"Contract Address: {contract.address}")
    i = 1

    # Until randomness received
    while(True):
        print(f"Checking #{i} in {sleep_time} secs...")
        # Wait
        time.sleep(sleep_time)
        # Get last mined block num
        to_block = len(chain)

        # Check if randomness received
        # 🔗 See https://docs.etherscan.io/api-endpoints/logs
        response = requests.get(
            config["networks"][network.show_active()]["explorer_api"],
            params={
                "module": "logs",
                "action": "getLogs",
                "fromBlock": from_block,
                "toBlock": to_block,
                "address": contract.address,
                # TODO: Make sure topic0 is working properly
                # 'ReceiveRandomNumber(uint256[] numReceived)'
                "topic0": "0x2b9b68a0f2880244fa2999d92504cb5dc5933b0ab58e5bede6671e51de8b74f2",
                "apikey": config["api_keys"]["etherscan"],
            },
            headers={'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.93 Safari/537.36'}).json()
        # Return randomness if received
        print(response)
        if response['status'] == "1":
            print(f"Randomness received!\n")
            return int(response['result'][0]['topics'][0], 16)

        # Half sleep time if longer than 15 seconds
        if(sleep_time > 15):
            sleep_time /= 2

        i += 1
        if i > 15:
            print("Randomness not received. Further investigation required.")
            return

def listen_for_event(brownie_contract, event, timeout=200, poll_interval=2):
    """Listen for an event to be fired from a contract.
    We are waiting for the event to return, so this function is blocking.
    Args:
        brownie_contract ([brownie.network.contract.ProjectContract]):
        A brownie contract of some kind.
        event ([string]): The event you'd like to listen for.
        timeout (int, optional): The max amount in seconds you'd like to
        wait for that event to fire. Defaults to 200 seconds.
        poll_interval ([int]): How often to call your node to check for events.
        Defaults to 2 seconds.
    """
    web3_contract = web3.eth.contract(
        address=brownie_contract.address, abi=brownie_contract.abi
    )
    start_time = time.time()
    current_time = time.time()
    event_filter = web3_contract.events[event].createFilter(fromBlock="latest")
    print(f"Checking for event ({event}) every {poll_interval} seconds for a total of {timeout} seconds...")
    while current_time - start_time < timeout:
        for event_response in event_filter.get_new_entries():
            if event in event_response.event:
                print("Found event!")
                return event_response
        print("...")
        time.sleep(poll_interval)
        current_time = time.time()
    print_line(f"Timeout of {timeout} seconds reached, no event found.")
    return {"event": None}