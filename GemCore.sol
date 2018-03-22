pragma solidity ^0.4.16;

import "./GemMinting.sol";

contract GemCore is GemMinting {

	function getGem(uint256 _id)
        external
        view
        returns (
        uint256 hardness,
        uint256 weight,
        uint256 shape,
        uint256 mineTime,
        uint256 category,
        address owner,
        bool isOnSale
    ) {
        Gems storage gem = gemstones[_id];

        hardness = uint256(gem.hardness);
        weight = uint256(gem.weight);
        shape = uint256(gem.shape);
        mineTime = uint256(gem.mineTime);
        category = uint256(gem.category);
        owner = ownerOf(_id);

        Sale storage sale = gemToSale[_id];
        isOnSale = _isOnSale(sale);

    }

}