// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/ArcSplit.sol";

/// @notice Deploy ArcSplit to Arc mainnet (chain 5042).
/// @dev Run: forge script script/Deploy.s.sol --rpc-url $ARC_RPC_URL --broadcast
///      Requires ARC_RPC_URL and a funded private key (--private-key or keystore).
contract Deploy is Script {
    function run() external returns (ArcSplit) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        ArcSplit splitter = new ArcSplit();
        vm.stopBroadcast();
        console2.log("ArcSplit deployed at:", address(splitter));
        return splitter;
    }
}
