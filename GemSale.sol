pragma solidity ^0.4.16;

import "./GemBase.sol";

contract GemSale is GemBase {

    struct Sale {
        
        //Seller of gem
        address seller;
        //Selling price set by the seller
        uint256 sellPrice;
        //Time when put up on Sale
        uint64 startedAt;
    }


    mapping(uint256 => Sale) gemToSale; //gemId to Sale

    event SaleCreated(uint256 tokenId, uint256 sellPrice, uint64 startedAt);
    event SaleSuccessful(uint256 tokenId, uint256 sellPrice, address winner);
    event SaleCancelled(uint256 tokenId, address seller);

    // function GemCore(string _name, string _symbol) public {
    //     GemCore(_name, _symbol);
    //}


    function _addSale(uint256 _gemId, Sale _sale) internal {

        // Add sale to gemToSale data structure
        gemToSale[_gemId] = _sale;
        // Fire Sale created event
        SaleCreated(_gemId, _sale.sellPrice, _sale.startedAt);
    }

    function _removeSale(uint256 _tokenId) internal {
        delete gemToSale[_tokenId];
    }

    function _isOnSale(Sale storage _sale) internal view returns (bool) {
        return (_sale.startedAt > 0);
    }

    // Function to create a sale for a gem
    function putOnSale(uint256 _gemId, uint256 _sellPrice, address _seller )
    public {
        
        // Sale creator must be the owner of the gem
        require(_owns(msg.sender, _gemId));
        // Creation of the sale
        Sale memory sale = Sale(_seller, _sellPrice, uint64(now));
        // Calling internal function to add the sale to the state variables
        _addSale(_gemId, sale);
    }

    // Function that handles the bid internally
    function _bid(uint256 _gemId, uint256 _bidAmount) internal {
        
        // Get the Sale for this gemId
        Sale storage sale = gemToSale[_gemId];
        // Check if gem is still on sale
        require(_isOnSale(sale));
        // Check if bid amount is greater than or equal to sale price
        require(_bidAmount >= sale.sellPrice);
        
        // Get seller before deleting the sale struct
        address gemSeller = sale.seller;
        // Delete the sale as sale was Successful
        _removeSale(_gemId);

        // Transfer the sale proceeds to seller
        gemSeller.transfer(_bidAmount);

    }

    // Function to place bid
    function bid(uint256 _gemId) external payable {
        address seller = gemToSale[_gemId].seller;
        _bid(_gemId, msg.value);
        _transfer(seller, msg.sender, _gemId);
        SaleSuccessful(_gemId, msg.value, msg.sender);
    }

    // Function to cancel sale
    function cancelSale(uint256 _gemId) external {
        Sale storage sale = gemToSale[_gemId];
        require(_owns(msg.sender, _gemId));
        require(_isOnSale(sale));
        _removeSale(_gemId);
    }

}