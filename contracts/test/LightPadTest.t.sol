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
        LightPad.IDOInfor memory idoInfor = LightPad.IDOInfor({
            isOpen: true,
            isEnded: false,
            projectName: "TC Protocol",
            tokenAddr: makeAddr("TCP"),
            pricePerToken: 0.02 ether,
            totalRaise: 100000e18,
            phase: 1
        });

        vm.prank(owner);
        lightPad.createIDO(idoInfor);
    }
}
