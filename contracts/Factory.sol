pragma solidity 0.7.0;

import "./WrappedSLP.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Factory - Allow to deploy arbitrary WSLP tokens.
contract Factory is Ownable {
    mapping(string => address) public getErc20; // slp-wslp keypairs
    address[] public allTokens; // all wslp addressses
    string[] public allSlp; // all slp addresses

    event WslpCreated(string indexed _slp, address indexed _erc20);

    /// @dev Read the amount of supported WSLP.
    /// @return Number of supported WSLP.
    function allPairsLength() external view returns (uint256) {
        return allSlp.length;
    }

    /// @dev Deploy new ERC20 that represents wrapped SLP.
    /// @param _slp Address of the SLP token in BCH.
    /// @param _symbol Token's symbol.
    /// @param _name Token's name.
    /// @return _erc20 New WSLP address.
    function createWslp(
        string memory _slp,
        string memory _symbol,
        string memory _name
    ) external returns (address _erc20) {
        require(getErc20[_slp] == address(0), "Factory: erc20 exist");
        WrappedSLP wrappedSLP = new WrappedSLP(_slp, _symbol, _name);
        wrappedSLP.transferOwnership(owner());
        _erc20 = address(wrappedSLP);
        allTokens.push(_erc20);
        allSlp.push(_slp);
        emit WslpCreated(_slp, _erc20);
    }
}
