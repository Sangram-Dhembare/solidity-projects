// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console2 } from "forge-std/Script.sol";
import { ElectionAnchor } from "../src/ElectionAnchor.sol";
import { PollManager } from "../src/PollManager.sol";
import { SimpleVoting } from "../src/SimpleVoting.sol";

contract DeployScript is Script {
    /// @notice Deploys the example fixed-candidate vote and poll manager.
    /// @dev Signing is provided by Foundry CLI options; this script reads no secrets.
    function run()
        external
        returns (SimpleVoting voting, PollManager manager, ElectionAnchor anchor)
    {
        string[] memory candidateNames = new string[](2);
        candidateNames[0] = "Alice";
        candidateNames[1] = "Bob";

        vm.startBroadcast();
        voting = new SimpleVoting(candidateNames);
        manager = new PollManager();
        anchor = new ElectionAnchor();
        vm.stopBroadcast();

        console2.log("SimpleVoting", address(voting));
        console2.log("PollManager", address(manager));
        console2.log("ElectionAnchor", address(anchor));
    }
}
