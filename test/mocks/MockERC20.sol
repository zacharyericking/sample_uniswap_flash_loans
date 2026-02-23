// Author: Zachary King - github.com/zacharyericking/sample_uniswap_flash_loans

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.26;

import { IERC20 } from "../../src/interfaces/IERC20.sol";

/// @title MockERC20
/// @notice Simple ERC20 implementation used by tests to model token behavior.
/// @dev Supports repository test objective by providing deterministic balances/allowances.
contract MockERC20 is IERC20 {
    error InsufficientBalance();
    error InsufficientAllowance();
    error InvalidAddress();

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice Initializes token metadata for a mock token instance.
    /// @param _name Token name.
    /// @param _symbol Token symbol.
    /// @param _decimals Token decimals precision.
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @notice Transfers token balance from caller to recipient.
    /// @param to Recipient address.
    /// @param amount Transfer amount.
    /// @return `true` on success.
    function transfer(address to, uint256 amount) external override returns (bool) {
        if (to == address(0)) revert InvalidAddress();
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Sets allowance from caller to spender.
    /// @param spender Spender address.
    /// @param amount New allowance amount.
    /// @return `true` on success.
    function approve(address spender, uint256 amount) external override returns (bool) {
        if (spender == address(0)) revert InvalidAddress();
        allowance[msg.sender][spender] = amount;
        return true;
    }

    /// @notice Transfers tokens using spender allowance model.
    /// @param from Source address.
    /// @param to Destination address.
    /// @param amount Transfer amount.
    /// @return `true` on success.
    function transferFrom(address from, address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (from == address(0) || to == address(0)) revert InvalidAddress();
        uint256 current = allowance[from][msg.sender];
        if (current < amount) revert InsufficientAllowance();
        if (current != type(uint256).max) {
            allowance[from][msg.sender] = current - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Mints test tokens to a destination account.
    /// @param to Recipient address.
    /// @param amount Mint amount.
    function mint(address to, uint256 amount) external {
        if (to == address(0)) revert InvalidAddress();
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    /// @notice Internal balance movement primitive.
    /// @param from Source address.
    /// @param to Destination address.
    /// @param amount Transfer amount.
    function _transfer(address from, address to, uint256 amount) internal {
        if (balanceOf[from] < amount) revert InsufficientBalance();
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}
