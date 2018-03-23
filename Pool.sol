//-----------------------------------------
//-----Pirl shared Masternode contract-----
//-----------------------------------------
//-----Author: Jonathan Lindgren-----------
//-----Discord: @Kurret--------------------
//-----------------------------------------
//-----Use at your own risk, the author----
//-----takes no responsibility in the -----
//-----case of loss of funds---------------
//-----------------------------------------
//-----------------------------------------
//----Distributed under the MIT License----




pragma solidity ^0.4.15;


//some functions for the masternode contract
contract MN {
	function nodeRegistration() public payable returns (bool paid);
	function disableNode() public returns (bool disabled);
	function withdrawStake() public returns (bool withdrawn);
	function nodeCost() public constant returns (uint256);

}

//Shared masternode contract
contract Pool {


	//owner of the contract, the person who is supposed to run the node
	address owner;


	//addresses of investors	
	mapping (address=>bool) allowedAddresses;

	//number of votes cast to override node operator
	uint votes;

	//required votes to override node operator
	uint requiredVotes;

	//total amount deposited
	uint256 totalDeposit;

	//deposits
	mapping (address=>uint256) balances;

	//keeps track of who has voted in case of an investor uprising
	mapping (address=>bool) hasVoted;
	
	//nodeActive=true if node has been registered at the masternode contract, set to false after stake is withdrawn
	bool nodeActive;

	//minimum deposit
	uint minDeposit;

	//maximum deposit (might be recommended to set minDeposit=maxDeposit
	uint maxDeposit;


	//this is set to the amount of unclaimed rewards when the masternode stake is withdrawn
	uint256 canBeClaimed=0;

	//masternode contract
	MN mn;

	//node closed
	bool nodeClosed;
		

	//cost of a node
	uint256 nodeCost;

	//bonus reward for owner
	uint256 ownerBonus;

	//constructor
	function Pool(address _masternodeContract, uint _minDeposit, uint _maxDeposit, address _owner,uint256 _votingLimit, uint256 _ownerBonus) public {
		require(minDeposit<=maxDeposit);
		mn=MN(_masternodeContract);
		owner=_owner;
		ownerBonus=_ownerBonus;
		minDeposit=_minDeposit;
		maxDeposit=_maxDeposit;
		nodeCost=mn.nodeCost();

		require(maxDeposit<=nodeCost);
		require(requiredVotes<=nodeCost);
		require(ownerBonus<=nodeCost);
		allowedAddresses[_owner]=true;
		requiredVotes=_votingLimit;


	}

	function makeIdentificationTransaction(address _poseidonAddress) payable public returns (bool) { 
		require(msg.sender==owner);
		_poseidonAddress.transfer(msg.value);
		return true;
		
	}


	function getMasternodeContractAddress() constant public returns (address){
		return address(mn);
	}

	//add addresses for investors
	function addAddress(address a) public returns (bool){
		require(msg.sender==owner);
		allowedAddresses[a]=true;
		return true;
	}

	
	//trasfer share in node to new address, can only be done while node is running
	function transferShare(address _to) public returns (bool){ 
		require(nodeActive);
		balances[_to]==balances[msg.sender];
		balances[msg.sender]==0;
		allowedAddresses[msg.sender]=false;
		allowedAddresses[_to]=true;
		Transfer(msg.sender,_to);
		return true;
	}

	function transferOwnership(address _to) public returns (bool){
		require(owner==msg.sender);
		allowedAddresses[_to]=true;
		owner=_to;
		TransferOwner(msg.sender,_to);

		return true;

	}


	//vote to disable the node
	function voteToDisable() public returns (bool){
		require(!hasVoted[msg.sender]);
		require(allowedAddresses[msg.sender]);
		hasVoted[msg.sender]=true;
		votes=votes+balances[msg.sender];
		return true;
	}


	//remove vote cast
	function removeVote() public returns (bool){
		require(hasVoted[msg.sender]);
		require(allowedAddresses[msg.sender]);
		hasVoted[msg.sender]=false;
		votes=votes-balances[msg.sender];
		return true;		
	}


	//returns number of votes cast
	function getVotes() constant public returns (uint256){
		return votes;
	}


	//returns required number of votes to override node operator
	function getRequiredVotes() constant public returns (uint256){
		return requiredVotes;
	}


	//returns the reward bonus for the owner
	function getOwnerBonus() constant public returns (uint256){
		return ownerBonus;
	}


	//activate node
	function activateNode() public payable returns (bool){
		require(this.balance>=nodeCost);
		require(msg.sender==owner);
		require(nodeActive==false);
		require(nodeClosed==false);
		mn.nodeRegistration.value(nodeCost)();
		nodeActive=true;
		ActivateNode(msg.sender);
		return true;
	}


	//get the cost of a node, as previously obtained from the masternode contract
	function getNodeCost() constant public returns (uint256){
		return nodeCost;
	}

	
	//disable the node, can be called by node operator or by an investor in case enough votes have been cast
	function disableNode() public returns (bool){
		require((votes>=requiredVotes)||msg.sender==owner);
		require(allowedAddresses[msg.sender]);
		mn.disableNode();
		DisableNode(msg.sender);
		return true;
	}


	//withdraw stake from masternode contract, can be called by node operator or by an investor in case enough votes have been cast
	function withdrawStake() public returns (bool){
		require((votes>=requiredVotes)||msg.sender==owner);
		require(allowedAddresses[msg.sender]);
		canBeClaimed=this.balance;
		mn.withdrawStake();
		nodeActive=false;
		nodeClosed=true;
		WithdrawStake(msg.sender);
		return true;
	}


	//returns owner of the contract (the node operator)
	function getOwner() constant public returns (address){
		return owner;
	}

	
	//deposit money to the contract before node registration
	function deposit() public payable returns (bool){
		require(nodeActive==false);
		require(nodeClosed==false);
		require(totalDeposit+msg.value<=nodeCost);
		require(msg.value+balances[msg.sender]>=minDeposit);
		require(msg.value+balances[msg.sender]<=maxDeposit);
		require(allowedAddresses[msg.sender]);
		balances[msg.sender]+=msg.value;
		totalDeposit+=msg.value;
		Deposit(msg.value,msg.sender);
		return true;
	}


	//return share of investor
	function getBalance(address a) constant public returns (uint256){
		return balances[a];

	}


	bool ownerHasWithdrawn=false;
	//withdraw deposit
	function withdrawDeposit() public returns (bool){
		require(nodeActive==false);
		uint256 b=balances[msg.sender];
		uint256 bonus=0;
		if ((!ownerHasWithdrawn)&&(msg.sender==owner)){
			bonus=ownerBonus;
			ownerHasWithdrawn=true;
		}
		balances[msg.sender]==0;


		msg.sender.transfer(b+((b+bonus)*canBeClaimed)/(ownerBonus+nodeCost));
		WithdrawDeposit(b+((b+bonus)*canBeClaimed)/(ownerBonus+nodeCost),msg.sender);
		return true;
	}


	bool distributingRewards;

	//distribute rewards to investors proportionally to share
	function distribute(address[] a) public returns (bool){
		require(!distributingRewards);
		require(nodeActive);
		require(allowedAddresses[msg.sender]);
		distributingRewards=true;
		uint256 check=0;
		for(uint256 i=0;i<a.length;i++) {
			check=check+balances[a[i]];
		}

		require(check==nodeCost);

		//reuse this integer as a temporary store of the current balance
		check=this.balance;

		for(i=0;i<a.length;i++) {
			a[i].transfer((balances[a[i]]*check)/(ownerBonus+nodeCost));
		}		
		owner.transfer((ownerBonus*check)/(ownerBonus+nodeCost));
		distributingRewards=false;
		Distribute(check,msg.sender);

		return true;
	}
	

	//events
	event Distribute(uint256 _value, address _who);
	event ActivateNode(address _who);
	event DisableNode(address _who);
	event WithdrawStake(address _who);
	event Deposit(uint256 _value,address _who);
	event WithdrawDeposit(uint256 _value, address _who);
	event Transfer(address _from, address _to);
	event TransferOwner(address _from, address _to);


	
	function() payable {

	}



}



