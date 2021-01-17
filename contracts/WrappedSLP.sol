// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";

/// @title Wrapped SLP - Allows to SLP tokens to the Ethereum network.
contract WrappedSLP is ERC20, Ownable {
    event SlpLocked(
        address indexed _account,
        uint256 _amount,
        string indexed _slpTrx
    );
    event SlpLockedBack(address indexed _account, uint256 _id, uint256 _amount);
    event BurnFees(uint256 _amount);
    event SlpUnlockRequested(
        string indexed _token,
        address indexed _account,
        uint256 _amount,
        string indexed _slpAddr
    );

    enum Status {BURNED, REQUESTED, EXEC, CANCELED}

    struct Withdraw {
        uint256 amount; // amount of tokens claimed on BCH
        Status status; // withdrawal status
    }
    struct User {
        uint256 head; // last deposit index
        uint256 loss; // amount of borrowe fee
        uint256 lastUpdate; // las time fee was charged
        mapping(uint256 => Withdraw) withdraws; // withdrawal requests
    }

    string public slpAddress; // address of the original SLP
    uint256 public chargePerSecRate = 316880878; // holders fee, 1% per year
    mapping(address => User) public users; // accounts info

    /// @dev Contract constructor sets initial owner and grants the rights.
    /// @param _slp Address of the original slp.
    /// @param _name Token's name.
    /// @param _symbol Token's symbol.
    /// @param _decimals Number of decimals.
    constructor(
        string memory _slp,
        string memory _symbol,
        string memory _name,
        uint8 _decimals
    ) ERC20(_name, _symbol) Ownable() {
        slpAddress = _slp;
        _setupDecimals(_decimals);
    }

    /// @dev Mints new wrapped tokens to the address.
    /// @param _account Tokens receiver.
    /// @param _amount Asset's quatity.
    /// @param _slpTrx Hash of the transaction where original SLP sent.
    function deposit(
        address _account,
        uint256 _amount,
        string memory _slpTrx
    ) external onlyOwner {
        _mint(_account, _amount);
        emit SlpLocked(_account, _amount, _slpTrx);
    }

    /// @dev Burns wrapped tokens to request original SLP.
    /// @param _amount Asset's quatity.
    /// @param _slpAddr Address of the SLP receiver.
    function withdraw(uint256 _amount, string memory _slpAddr) external {
        address account = _msgSender();
        _burn(account, _amount);
        users[account].withdraws[users[account].head++].amount = _amount;
        emit SlpUnlockRequested(slpAddress, account, _amount, _slpAddr);
    }

    /// @dev Requests canceling the original SLP token transfer.
    /// @param _id Withdraw request id.
    function requestCancel(uint256 _id) external {
        address account = _msgSender();
        require(users[account].head > _id, "WrappedSLP: request doesn't exist");
        require(
            users[account].withdraws[_id].status == Status.BURNED,
            "WrappedSLP: wrong request status"
        );
        users[account].withdraws[_id].status = Status.REQUESTED;
    }

    /// @dev Returns wrapped SLP after canceling the original SLP unlock.
    /// @param _account Address of the account that requested canceling.
    /// @param _id Withdraw request id.
    function execCancel(address _account, uint256 _id) external onlyOwner {
        require(
            users[_account].withdraws[_id].status == Status.REQUESTED,
            "WrappedSLP: wrong request status"
        );
        uint256 amount = users[_account].withdraws[_id].amount;
        _mint(_account, amount);
        users[_account].withdraws[_id].status = Status.CANCELED;
        emit SlpLockedBack(_account, _id, amount);
    }

    /// @dev Regects canceling the original SLP unlock.
    /// @param _account Address of the account that requested canceling.
    /// @param _id Withdraw request id.
    function rejectCancel(address _account, uint256 _id) external onlyOwner {
        require(
            users[_account].withdraws[_id].status == Status.REQUESTED,
            "WrappedSLP: wrong request status"
        );
        users[_account].withdraws[_id].status = Status.EXEC;
    }

    /// @dev Burns holder fees after the original SLP tokens burn or transfer to zero address.
    function burnFees() external onlyOwner {
        uint256 amount = balanceOf(address(this));
        _burn(address(this), amount);
        emit BurnFees(amount);
    }

    /// @dev Withdraw fee from the account.
    /// @param _account Address of the account that holds tokens.
    function _chargeHolderFee(address _account) internal {
        User storage userInfo = users[_account];
        uint256 balance = balanceOf(_account);
        if (balance > 0 && block.timestamp > userInfo.lastUpdate) {
            userInfo.loss =
                (block.timestamp - userInfo.lastUpdate) *
                chargePerSecRate;
            uint256 payableLoss = userInfo.loss / 1e18;
            if (payableLoss > 0) {
                super._transfer(
                    _account,
                    address(this),
                    Math.min(payableLoss, balance)
                );
                userInfo.loss = userInfo.loss - payableLoss * 1e18;
            }
        }
        userInfo.lastUpdate = block.timestamp;
    }

    /// @dev Transfer assets between addresses.
    /// @param _sender Address of the account that sends tokens.
    /// @param _recipient Address of the account that receivers tokens.
    /// @param _amount Amount of tokens to ne sent.
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal override {
        if (_sender != address(this) && _sender != address(0))
            _chargeHolderFee(_sender);
        if (_recipient != address(this) && _recipient != address(0))
            _chargeHolderFee(_recipient);
        super._transfer(_sender, _recipient, _amount);
    }
}
