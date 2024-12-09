// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// Interfaz estándar ERC20 para los tokens que usarás en el swap.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// Interfaz del contrato de Uniswap V3 para realizar el intercambio.
interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract UniV3Swap {
    // Dirección del Router de Uniswap V3 en Sepolia
    address private constant UNIV3_ROUTER = 0x4D73A4411CA1c660035e4AECC8270E5DdDEC8C17;

    // Función para realizar el intercambio
    function swap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint160 sqrtPriceLimitX96
    ) external {
        // Verificar que el contrato ha recibido la cantidad adecuada de tokens
        uint256 balanceBefore = IERC20(tokenIn).balanceOf(address(this));
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");
        uint256 balanceAfter = IERC20(tokenIn).balanceOf(address(this));
        uint256 receivedAmount = balanceAfter - balanceBefore;

        require(receivedAmount == amountIn, "Incorrect token amount received");

        // Aprobar el router de Uniswap V3 para gastar los tokens
        require(IERC20(tokenIn).approve(UNIV3_ROUTER, amountIn), "Approve failed");

        // Definir los parámetros para el intercambio de Uniswap V3
        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        // Realizar el intercambio
        ISwapRouter02(UNIV3_ROUTER).exactInputSingle(params);
    }
}
