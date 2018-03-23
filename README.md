# PirlSharedMasternodeContract
Contract for sharing ownership of a masternode on the Pirl network. This is currently an experimental contract and can contain serious vulnerabilities. The author takes no responsibility in the case of loss of funds

# 1.Construction:
The contract's contructor takes the parameters

_masternodeContract: the address of the masternode contract

_minDeposit: the minimum allowed deposit

_maxDeposit: the maximum allowed deposit

_owner: the owner of the contract (this should be the node operator)

_votingLimit: minimum number of votes required for making a collective decision (to be explained later)

_ownerBonus: bonus to the owner for running the node

# 2.Add investors:
The owner must approve who will be allowed to buy a share in the node. This is done by calling the function addAddress(address)

# 3.Deposit Pirl:
to deposit pirl to the node, send pirl to the address while calling the function deposit(). This can only be done before the node has been activated, and the final value must be between minDeposit and maxDeposit (but it is allowed to make many deposits as long as the balance after the first deposit is larger than minDeposit). Moreover, the total deposited money (the balance of the contract) can not exceed the cost of a node.

# 4.Activate node:
To activate the node (register it at the masternode contract by calling the function nodeRegistration()), the owner must call activateNode() which in turn calls nodeRegistration() in the mastearnode contract. This requires that the balance of the contract is greater or equal to the cost of a node.

# 5.Disable node:
Disable the node by calling disableNode (which in turn calls disableNode on the masternode contract). The owner can always call this function but any investor can call it given that enough investors have voted to do so (see 9. Voting)

# 6.Withdraw stake:
Withdraw the stake from the masternode contract (which in turn calls withdrawStake on the masternode contract). The owner can always call this function but any investor can call it given that enough investors have voted to do so (see 9. Voting). Note that disableNode must be called before calling thus function or the call to the masternode contract will fail.

# 7.Withdraw deposit:
Can be called either before the node has been activated or after the stake has been withdrawn from the masternode contract and will withdraw the original deposit plus any remaining leftover from masternode rewards if it is called after the node has been closed (rewards will be allocated proportionally to the stake in the node).

# 8.Withdraw rewards while node is running:
Call withdraw() while the node is running to claim your share of the rewards.

# 9.Voting to disable node:
To prevent the owner from malicious practices (such as holding investors money hostage while not running the node), the node can be disabled by voting. To cast a vote to disable the node, call voteToDisable. This will increment the uint votes with the balance of the caller. After votes>requiredVotes is satisfied, where requiredVotes is set during creation of the contract, any investor can call the functions disableNode and withdrawStake.

# 10.Transfer share:
Share in the node can be transferred (in whole) to another address by calling transferShare(address). This can only be done while node is running.

# 11.Transfer ownership:
Ownership can be transferred by calling the function transferOwnership(address).



# COMMENTS:
Please always check that the masternode contract address is correct by calling getMasternodeContractAddress before putting in any pirl into the contract. Also check get that you agree with the voting requirement by calling getRequiredVotes, as well as the bonus for the masternode operator by calling getOwnerBonus.



















