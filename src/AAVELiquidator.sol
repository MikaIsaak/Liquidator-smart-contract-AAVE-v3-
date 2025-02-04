// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

contract AAVELiquidator is FlashLoanSimpleReceiverBase, Ownable {
    using SafeERC20 for IERC20;

    struct LiquidationParams {
        address collateralAsset;
        address debtAsset;
        address user;
        uint256 debtToCover;
        bool receiveAToken;
    }

    LiquidationParams private liquidationParams;

    /**
     * @dev Initializes the contract with the Aave PoolAddressesProvider.
     * @param _addressProvider Address of the Aave PoolAddressesProvider.
     */
    constructor(address _addressProvider)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
        Ownable(msg.sender)
    {}

    /**
     * @notice Executes the flash loan operation.
     * @param asset The address of the borrowed asset.
     * @param amount The amount of the borrowed asset.
     * @param premium The fee for the flash loan.
     * @param initiator The address that initiated the flash loan.
     * @param params Encoded parameters for the liquidation.
     * @return True if the operation is successful.
     */
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        override
        returns (bool)
    {
        require(initiator == address(this), "Unauthorized initiator");

        liquidationParams = abi.decode(params, (LiquidationParams));

        IERC20(asset).approve(address(POOL), amount);

        POOL.liquidationCall(
            liquidationParams.collateralAsset,
            liquidationParams.debtAsset,
            liquidationParams.user,
            liquidationParams.debtToCover,
            liquidationParams.receiveAToken
        );

        uint256 amountToReturn = amount + premium;

        IERC20(asset).approve(address(POOL), amountToReturn);

        require(IERC20(asset).balanceOf(address(this)) >= amountToReturn, "Insufficient funds to repay flash loan");

        return true;
    }

    /**
     * @notice Initiates a liquidation using a flash loan.
     * @param collateralAsset The address of the collateral asset.
     * @param debtAsset The address of the debt asset.
     * @param user The address of the user being liquidated.
     * @param debtToCover The amount of debt to cover in the liquidation.
     * @param receiveAToken If true, the collateral is received as aTokens.
     */
    function executeLiquidation(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external onlyOwner {
        require(collateralAsset != address(0), "Invalid collateral asset");
        require(debtAsset != address(0), "Invalid debt asset");
        require(user != address(0), "Invalid user address");

        // Prepare liquidation parameters
        bytes memory params = abi.encode(
            LiquidationParams({
                collateralAsset: collateralAsset,
                debtAsset: debtAsset,
                user: user,
                debtToCover: debtToCover,
                receiveAToken: receiveAToken
            })
        );

        // Request flash loan
        POOL.flashLoanSimple(address(this), debtAsset, debtToCover, params, 0);
    }

    /**
     * @notice Withdraws a specific token from the contract.
     * @param token The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Invalid amount");

        IERC20(token).safeTransfer(owner(), amount);
    }

    /**
     * @notice Withdraws the entire balance of a specific token.
     * @param token The address of the token to withdraw.
     */
    function withdrawFullTokenBalance(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        IERC20(token).safeTransfer(owner(), balance);
    }

    /**
     * @notice Withdraws ETH from the contract.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient ETH balance");

        payable(owner()).transfer(amount);
    }

    /**
     * @notice Withdraws the entire ETH balance from the contract.
     */
    function withdrawFullETHBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        payable(owner()).transfer(balance);
    }

    /**
     * @dev Fallback function to receive ETH.
     */
    receive() external payable {}
}
