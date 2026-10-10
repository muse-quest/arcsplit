// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ArcSplit — minimal native-USDC payment splitter for Circle's Arc.
/// @notice Split one payment across N recipients by share weights in a single
///         transaction. On Arc the native gas token IS USDC, so the dollars
///         you split are paid for with the dollars you hold. No separate gas
///         token, no wrapping, no extra steps.
contract ArcSplit {
    address public immutable owner;

    event Split(
        address indexed sender,
        address[] recipients,
        uint256[] amounts,
        uint256 dustRefunded
    );
    event Swept(address indexed to, uint256 amount);

    error LengthMismatch();
    error NoRecipients();
    error ZeroAddress();
    error NoShares();
    error TransferFailed();
    error NotOwner();
    error Reentrant();

    bool private _locked;

    modifier nonReentrant() {
        if (_locked) revert Reentrant();
        _locked = true;
        _;
        _locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Split msg.value across recipients pro-rata by shares.
    /// @param recipients Payment destinations (no zero addresses).
    /// @param shares Weight per recipient; must match recipients length.
    /// @dev Dust from integer division is refunded to the sender.
    function split(
        address[] calldata recipients,
        uint256[] calldata shares
    ) external payable nonReentrant {
        if (recipients.length != shares.length) revert LengthMismatch();
        if (recipients.length == 0) revert NoRecipients();

        uint256 totalShares = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            if (recipients[i] == address(0)) revert ZeroAddress();
            totalShares += shares[i];
        }
        if (totalShares == 0) revert NoShares();

        uint256 value = msg.value;
        uint256[] memory amounts = new uint256[](recipients.length);
        uint256 distributed = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = (value * shares[i]) / totalShares;
            amounts[i] = amount;
            distributed += amount;
            (bool ok, ) = recipients[i].call{value: amount}("");
            if (!ok) revert TransferFailed();
        }

        uint256 dust = value - distributed;
        if (dust > 0) {
            (bool ok, ) = msg.sender.call{value: dust}("");
            if (!ok) revert TransferFailed();
        }

        emit Split(msg.sender, recipients, amounts, dust);
    }

    /// @notice Recover any stranded balance (e.g. forced via selfdestruct).
    function sweep() external {
        if (msg.sender != owner) revert NotOwner();
        uint256 bal = address(this).balance;
        (bool ok, ) = owner.call{value: bal}("");
        if (!ok) revert TransferFailed();
        emit Swept(owner, bal);
    }

    receive() external payable {}
}
