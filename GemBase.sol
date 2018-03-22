pragma solidity ^0.4.16;

contract Ownable {
	address private owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	function Ownable() public {
		owner = msg.sender;
	}

	function getOwner() public constant returns (address currentOwner) {
		return owner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	// Ownership can be transfered by current owner only
    // New owner should be a non-zero address
	function transferOwnership(address _newOwner) onlyOwner {
		require(_newOwner != address(0));
		newOwner = _newOwner;
	}

	// Ownership can be accepted by the new onwer only
    // Fires an Ownership transfer event
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}

contract ERC721 {
	// Required methods
    function totalSupply() public view returns (uint256 total);		//////
    function balanceOf(address _owner) public view returns (uint256 balance);	//////
    function ownerOf(uint256 _tokenId) public view returns (address owner);	//////
    function approve(address _to, uint256 _tokenId) external;		/////
    function transfer(address _to, uint256 _tokenId) external;		/////
    function transferFrom(address _from, address _to, uint256 _tokenId) external; /////

    // Optional
    //function getName() public view returns (string tokenName);				//////
    //function getSymbol() public view returns (string tokenSymbol);			//////
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    //function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

}

contract GemBase is ERC721, Ownable {

	struct Gems {

		// Properties that define the gem
		uint256 hardness;
		uint256 weight;
		uint256 shape;

		// Timestamp represting the time when this gem came into existence;
		uint256 mineTime;
		// Cooldown time for gem after a metamorphosis session
		uint256 category;
	}

	// Array representing each gem in existence
	//gemID is an index to this array represnting a particular gem.
	Gems[] gemstones;

	// Owner of each gem is represnted by this gem to owner mapping
	// Each gem has a non-zero owner
	mapping (uint256 => address) private gemToOwner;
	// This represents the number of gems help by each owner
	mapping (address => uint256) private gemsOwnershipCount;
	// Mapping that allows an address to transfer a particular gem
	mapping (uint256 => address) public gemApproved;

	uint256 tokensInSupply;

	event Mined(address indexed owner, uint256 indexed gemID);

	//string name;
    //string symbol;

	//function GemsBase(string _name, string _symbol) public {
	//	name = _name;
	//	symbol = _symbol;
	//}

	//function getName() public view returns (string tokenName) {
	//	return name;
	//}

	//function getSymbol() public view returns (string tokenSymbol) {
	//	return symbol;
	//}

	function totalSupply() public view returns (uint256 total) {
		return tokensInSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return gemsOwnershipCount[_owner];
	}

	function ownerOf(uint256 _tokenId) public view returns (address gemOwner) {
		return gemToOwner[_tokenId];
	}

	// Any verification must be done in calling function
	// This is just an internal function to be called by functions such as transfer and transferFrom
	function _transfer(address _from, address _to, uint256 _tokenId) internal {

        gemsOwnershipCount[_to]++;
        // transfer ownership
        gemToOwner[_tokenId] = _to;
        // When creating new gems, _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            gemsOwnershipCount[_from]--;
            // clear any previously approved ownership exchange
            delete gemApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
	}

	// Any verification must be done in calling function
	// This is just an internal function tobe called by functions such as approve
	function _approve(address _to, uint256 _tokenId) internal {
		gemApproved[_tokenId] = _to;
		// Event genrated in calling function as _from is required
	}

	// Checks if a given address (claimant) is actually the owner of the token
	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return gemToOwner[_tokenId] == _claimant;
    }

    // Checks if a given address (claimaint) is actually approved for the token
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return gemApproved[_tokenId] == _claimant;
    }

    function transfer(address _to, uint256 _tokenId) external {
    	// Check if function caller is the owner of the token
    	require(_owns(msg.sender, _tokenId));
    	// Do not allow tokens to be sent to 0x0 address
    	require(_to != address(0));
    	// Do not allow tokens to be sent to this contract
    	require(_to != address(this));
    	// Calling internal function to transfer and clear pending approvals
    	_transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
    	// Check if function caller is approved for the token
    	require(_approvedFor(msg.sender, _tokenId));
    	// Check if _from owns the token
    	require(_owns(_from, _tokenId));
    	// Do not allow tokens to be sent to 0x0 address
    	require(_to != address(0));
    	// Do not allow tokens to be sent to this contarct
    	require(_to != address(this));
    	// Calling internal function to transfer and cler pending approvals
    	_transfer(_from, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external {
    	// Check if function caller is the owner of the token
    	require(_owns(msg.sender, _tokenId));
    	// Calling internal function to approve the _to the address
    	_approve(_to, _tokenId);
    	// Emit the Approval event here as it is not done in the internal function
    	Approval(msg.sender, _to, _tokenId);
    }

    // Returns a list of all GemIDs owned by an address.
    // Must not be called by contarcts as it uses dynamic array which is supported for only
    // web3 calls and not contract-to-contract calls.
    // Also this method is fairly expensive if called internally as it iterates through the whole collection of created gems
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } 
        else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalGems = totalSupply();
            uint256 resultIndex = 0;

            // We start counting from the first gem with gemID 0 and count upto the totalGems
            uint256 gemId;

            for (gemId = 0; gemId <= totalGems; gemId++) {
                if (gemToOwner[gemId] == _owner) {
                    result[resultIndex] = gemId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _createGems(
        uint256 _hardness,
        uint256 _weight,
        uint256 _shape,
        uint256 _category,
        address _owner
    )
        internal
        returns (uint)
    {
        Gems memory _gem = Gems({
            hardness: _hardness,
            mineTime: uint64(now),
            weight: _weight,
            shape: _shape,
            category: _category
        });
        uint256 newGemId = gemstones.push(_gem)-1;

        // emit the Mined event
        Mined(_owner, newGemId);

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newGemId);
        tokensInSupply++;

        return newGemId;
    }

}