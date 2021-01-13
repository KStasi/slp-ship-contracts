// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";

/// @title Wrapped SLP - Allows to SLP tokens to the Ethereum network.
contract WrappedSLP is ERC1155, Ownable {
    event SlpLocked(uint256 indexed id, uint256 amount, string indexed slpTrx);
    event SlpLockedBack(uint256 indexed id, uint256 amount);
    event BurnFees(uint256[] indexed ids, uint256[] amounts);
    event SlpUnlockRequested(
        uint256 indexed id,
        uint256 amount,
        string indexed slpAddr
    );

    enum Status {BURNED, REQUESTED, EXEC, CANCELED}

    struct Withdraw {
        uint256 amount; // amount of tokens claimed on BCH
        Status status; // withdrawal status
    }
    struct TokenInfo {
        uint256 loss; // amount of borrowe fee
        uint256 lastUpdate; // las time fee was charged
    }
    struct User {
        uint256 head; // last deposit index
        mapping(uint256 => TokenInfo) tokensInfo; // assets fee info
        mapping(uint256 => Withdraw) withdraws; // withdrawal requests
    }

    uint256 public chargePerSecRate = 316880878; // holders fee, 1% per year
    mapping(address => User) public users; // accounts info

    /// @dev Contract constructor sets initial owner and grants the rights.
    constructor() ERC1155("http://slpship.com/wslp/{id}.json") Ownable() {}

    /// @dev Mints new wrapped tokens to the address.
    /// @param account Tokens receiver.
    /// @param id Asset id.
    /// @param amount Asset's quatity.
    /// @param slpTrx Hash of the transaction where original SLP sent.
    function deposit(
        address account,
        uint256 id,
        uint256 amount,
        string memory slpTrx
    ) external onlyOwner {
        _mint(account, id, amount, new bytes(0));
        emit SlpLocked(id, amount, slpTrx);
    }

    /// @dev Burns wrapped tokens to request original SLP.
    /// @param account Tokens burner.
    /// @param id Asset id.
    /// @param amount Asset's quatity.
    /// @param slpAddr Address of the SLP receiver.
    function withdraw(
        address account,
        uint256 id,
        uint256 amount,
        string memory slpAddr
    ) external {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(account, id, amount);
        users[_msgSender()].withdraws[users[_msgSender()].head++]
            .amount = amount;
        emit SlpUnlockRequested(id, amount, slpAddr);
    }

    /// @dev Requests canceling the original SLP token transfer.
    /// @param id Withdraw request id.
    function requestCancel(uint256 id) external {
        require(
            users[_msgSender()].head > id,
            "ERC1155: request doesn't exist"
        );
        require(
            users[_msgSender()].withdraws[id].status == Status.BURNED,
            "ERC1155: wrong request status"
        );
        users[_msgSender()].withdraws[id].status = Status.REQUESTED;
    }

    /// @dev Returns wrapped SLP after canceling the original SLP unlock.
    /// @param account Address of the account that requested canceling.
    /// @param id Withdraw request id.
    function execCancel(address account, uint256 id) external onlyOwner {
        require(
            users[_msgSender()].withdraws[id].status == Status.REQUESTED,
            "ERC1155: wrong request status"
        );
        uint256 amount = users[account].withdraws[id].amount;
        _mint(account, id, amount, new bytes(0));
        users[account].withdraws[id].status = Status.CANCELED;
        emit SlpLockedBack(id, amount);
    }

    /// @dev Regects canceling the original SLP unlock.
    /// @param account Address of the account that requested canceling.
    /// @param id Withdraw request id.
    function rejectCancel(address account, uint256 id) external onlyOwner {
        require(
            users[_msgSender()].withdraws[id].status == Status.REQUESTED,
            "ERC1155: wrong request status"
        );
        users[account].withdraws[id].status = Status.EXEC;
    }

    /// @dev Burns holder fees after the original SLP tokens burn or transfer to zero address.
    /// @param ids Assets to be burnt.
    function burnFees(uint256[] memory ids) external onlyOwner {
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = balanceOf(address(this), ids[i]);
        }
        _burnBatch(address(this), ids, amounts);
        emit BurnFees(ids, amounts);
    }

    /// @dev Withdraw fee from the account.
    /// @param account Address of the account that holds tokens.
    /// @param id Asset id.
    function _chargeHolderFee(address account, uint256 id) internal {
        TokenInfo storage tokenInfo = users[_msgSender()].tokensInfo[id];
        uint256 balance = balanceOf(account, id);
        if (balance > 0 && block.timestamp > tokenInfo.lastUpdate) {
            tokenInfo.loss =
                (block.timestamp - tokenInfo.lastUpdate) *
                chargePerSecRate;
            uint256 payableLoss = tokenInfo.loss / 1e18;
            if (payableLoss > 0) {
                safeTransferFrom(
                    account,
                    address(this),
                    id,
                    Math.min(payableLoss, balance),
                    new bytes(0)
                );
                tokenInfo.loss = tokenInfo.loss - payableLoss * 1e18;
            }
        }
        tokenInfo.lastUpdate = block.timestamp;
    }

    /// @dev Hook that is called before any token transfer.
    /// @param operator Address that executes the transfer.
    /// @param from Address that sends the tokens.
    /// @param to Address that receives the tokens.
    /// @param ids Assets to be transfered.
    /// @param amounts Quantity of the assets to be transfered.
    /// @param amounts Quantity of the assets to be transfered.
    /// @param data Data send to the recepient after transfer if it is the contract.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        for (uint256 i = 0; i < ids.length; i++) {
            if (from != address(this) && from != address(0))
                _chargeHolderFee(from, ids[i]);
            if (to != address(this) && to != address(0))
                _chargeHolderFee(to, ids[i]);
        }
    }
}
