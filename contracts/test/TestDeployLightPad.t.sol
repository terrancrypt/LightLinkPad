// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {LightPad} from "src/LP.sol";
import {LightPadToken} from "src/LightPadToken.sol";
import {DeployLightPad} from "script/DeployLightPad.s.sol";

contract TestDeployLightPad is Test {
    uint256 pegasusFork;
    string PEGASUS_RPC_URL = vm.envString("PEGASUS_RPC_URL");
    DeployLightPad deployer;

    function setUp() external {
        pegasusFork = vm.createFork(PEGASUS_RPC_URL);
        vm.selectFork(pegasusFork);
        deployer = new DeployLightPad();
    }

    function test_deploy() public {
        deployer.run();
    }
}
