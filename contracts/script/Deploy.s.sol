// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {RWAToken} from "../src/RWAToken.sol";
import {Treasury} from "../src/Treasury.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        // 1000 RWA tokens per 1 ETH
        uint256 tokensPerEth = 1000 * 1e18;

        vm.startBroadcast(deployerKey);

        // Deploy token with deployer as temporary owner
        RWAToken rwaToken = new RWAToken("RWA Token", "RWA", 18, deployer);

        // Deploy treasury; it will own the token and control minting
        Treasury treasury = new Treasury(address(rwaToken), tokensPerEth, deployer);

        // Hand mint authority to the treasury
        rwaToken.transferOwnership(address(treasury));

        vm.stopBroadcast();

        console.log("RWAToken deployed at:", address(rwaToken));
        console.log("Treasury deployed at:", address(treasury));
    }
}
