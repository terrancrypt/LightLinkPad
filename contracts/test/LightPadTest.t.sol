// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {LightPad} from "src/LightPad.sol";
import {LightPadToken} from "src/LightPadToken.sol";

contract LightPadTest is Test {
    uint256 pegasusFork;
    string PEGASUS_RPC_URL = vm.envString("PEGASUS_RPC_URL");

    LightPad lightPad;
    LightPadToken lightPadToken;

    address owner = makeAddr("owner");

    // An IDO Setup
    string constant PROJECT_NAME = "TC Protocol";
    address PROJECT_ADDRESS = makeAddr("Tc Protocol");
    uint256 constant PRICE_PER_TOKEN = 0.02 ether;
    uint256 constant TOTAL_RAISE = 200000 ether;

    function setUp() external {
        pegasusFork = vm.createFork(PEGASUS_RPC_URL);
        vm.selectFork(pegasusFork);

        vm.startBroadcast();
        lightPadToken = new LightPadToken();
        lightPad = new LightPad(
            owner,
            0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd,
            address(lightPadToken)
        );
        vm.stopBroadcast();
    }

    function test_can_createIDO() public {
        vm.prank(owner);
        lightPad.createIDO(
            PROJECT_NAME,
            PROJECT_ADDRESS,
            PRICE_PER_TOKEN,
            TOTAL_RAISE
        );

        uint256 idoCount = lightPad.getIDOCount();

        assert(idoCount == 1);
    }
}
