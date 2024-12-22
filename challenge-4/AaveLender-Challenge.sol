// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Definición de tipos de datos utilizados en Aave, como la estructura ReserveData
library DataTypes {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint16 id;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }
}

// Interfaz del contrato IPool de Aave, que permite interactuar con el protocolo
interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to) external returns (uint256);

    function getReserveData(
        address asset) external view returns (DataTypes.ReserveData memory);
}

// Interfaz estándar ERC20 para interactuar con los tokens (como DAI)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// Contrato principal que gestiona el staking y unstaking de tokens en Aave
contract AaveLender {
    // Dirección del contrato Aave Pool (en Sepolia Scroll Testnet)
    address public immutable AAVE_POOL_ADDRESS = 0x48914C788295b5db23aF2b5F0B3BE775C4eA9440;
    
    // Dirección del token a utilizar para el staking (DAI en este ejemplo)
    address public immutable STAKED_TOKEN_ADDRESS = 0x7984E363c38b590bB4CA35aEd5133Ef2c6619C40;

    // Función para depositar tokens en Aave y generar intereses
    function stake(uint amount) public {
        // 1. Transferir los tokens a este contrato
        require(IERC20(STAKED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // 2. Aprobar el contrato Aave Pool para gestionar los tokens
        IERC20(STAKED_TOKEN_ADDRESS).approve(AAVE_POOL_ADDRESS, amount);
        
        // 3. Llamar a la función supply del contrato Aave para depositar los tokens
        IPool(AAVE_POOL_ADDRESS).supply(STAKED_TOKEN_ADDRESS, amount, msg.sender, 0);
    }

    // Función para retirar tokens de Aave junto con las ganancias
    function unstake(uint amount) public {
        // Obtener la dirección del aToken (por ejemplo, aDAI para DAI)
        DataTypes.ReserveData memory reserveData = IPool(AAVE_POOL_ADDRESS).getReserveData(STAKED_TOKEN_ADDRESS);
        address aTokenAddress = reserveData.aTokenAddress;
        
        // 1. Transferir los aTokens de este contrato
        IERC20(aTokenAddress).transferFrom(msg.sender, address(this), amount);
        
        // 2. Aprobar el contrato Aave Pool para gestionar los aTokens
        IERC20(aTokenAddress).approve(AAVE_POOL_ADDRESS, amount);
        
        // 3. Llamar a la función withdraw del contrato Aave para retirar los tokens
        uint256 withdrawnAmount = IPool(AAVE_POOL_ADDRESS).withdraw(STAKED_TOKEN_ADDRESS, amount, msg.sender);
        
        require(withdrawnAmount == amount, "Withdraw failed");
    }
}
