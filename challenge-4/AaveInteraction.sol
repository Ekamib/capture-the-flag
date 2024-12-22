// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILendingPool {
    function getReserveData(address asset) external view returns (
        uint256 totalLiquidity,
        uint256 availableLiquidity,
        uint256 totalBorrowsStable,
        uint256 totalBorrowsVariable,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 stableBorrowRate,
        uint256 averageStableBorrowRate,
        uint256 reserveFactor,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress
    );
}

contract AaveInteraction {
    ILendingPool lendingPool = ILendingPool(0x3dfd1a344975cd9fa1e7b0f98c349fe021f02115); // Dirección de Lending Pool en Mainnet
    
    function getAaveTokenAddress(address asset) public view returns (address) {
        (, , , , , , , , , address aTokenAddress, , ) = lendingPool.getReserveData(asset);
        return aTokenAddress;
    }
}
