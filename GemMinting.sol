pragma solidity ^0.4.16;

import "./GemSale.sol";

contract GemMinting is GemSale {

	uint256 public constant MineLimit = 1000;

	uint256 public minePriceStart = 100 finney;
	uint256 public minePriceEnd = 1 ether;
	uint256 public currentMinePrice;
	uint256 public gemMined = 0;

	// Function to create new gems
    // Calls the internal fucntion _createGems
    // Only callable by owner fo the contract
    // These can be sold by the owner
    function createNewgems(
        uint256 _hardness,
        uint256 _weight,
        uint256 _shape,
        uint256 _category
    )
    external onlyOwner
    returns (uint) {
        _createGems(_hardness, _weight, _shape, _category, msg.sender);
    }

    function mineNewGem(uint256 _hardness, uint256 _weight, uint256 _shape, uint256 _category) public payable {
    	
    	// gems already mined must be within the limit
    	require(gemMined < MineLimit);

    	// Mining price for gem gradually increases as MineLimit is reached
    	// Early Adopters are benefitted
    	uint256 priceChange = minePriceEnd - minePriceStart;
    	currentMinePrice = minePriceStart + (priceChange * (gemMined/MineLimit));
    	
    	// Check if value sent is greater than current mine price
    	require(msg.value >= currentMinePrice);
    	_createGems(_hardness, _weight, _shape, _category, msg.sender);
    	gemMined++;
    }

    function getCurrentMinePrice() public view  returns (uint256) {
    	return currentMinePrice;
    }

    function getGemMined() public view  returns (uint256) {
    	return gemMined;
    }

}