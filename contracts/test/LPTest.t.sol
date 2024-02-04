// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {LightPad} from "src/LP.sol";
import {LightPadToken} from "src/LightPadToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract LightPadTest is Test {
    LightPad lightPad;
    LightPadToken lightPadToken;
    ERC20Mock mockUsdc;
    ERC20Mock projectToken;

    address mockAirnode = makeAddr("airnode");
    address owner = makeAddr("owner");

    function setUp() external {
        lightPad = new LightPad(owner, mockAirnode, address(lightPadToken));
        mockUsdc = new ERC20Mock();
        projectToken = new ERC20Mock();
    }

    function test_can_createProject() public {}

    function _owner_createProject() internal {
        vm.prank(owner);
        lightPad.createProject("TC Protocol", 0.25 ether, address(mockUsdc), 200000e18, address(projectToken), 200);
    }
}
