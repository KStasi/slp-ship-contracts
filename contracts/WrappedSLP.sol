// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";

contract WrappedSLP is ERC1155, Ownable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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
        uint256 amount;
        Status status;
    }
    struct TokenInfo {
        uint256 loss;
        uint256 lastUpdate;
    }
    struct User {
        uint256 head;
        mapping(uint256 => TokenInfo) tokensInfo;
        mapping(uint256 => Withdraw) withdraws;
    }
    uint256 public chargePerSecRate = 316880878; // 1% per year

    mapping(address => User) public users;

    constructor() ERC1155("http://slpship.com/wslp/{id}.json") Ownable() {}

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

    function deposit(
        address account,
        uint256 id,
        uint256 amount,
        string memory slpTrx
    ) external onlyOwner {
        _mint(account, id, amount, new bytes(0));
        emit SlpLocked(id, amount, slpTrx);
    }

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

    function rejectCancel(address account, uint256 id) external onlyOwner {
        require(
            users[_msgSender()].withdraws[id].status == Status.REQUESTED,
            "ERC1155: wrong request status"
        );
        users[account].withdraws[id].status = Status.EXEC;
    }

    function burnFees(uint256[] memory ids) external onlyOwner {
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = balanceOf(address(this), ids[i]);
        }
        _burnBatch(address(this), ids, amounts);
        emit BurnFees(ids, amounts);
    }
}
