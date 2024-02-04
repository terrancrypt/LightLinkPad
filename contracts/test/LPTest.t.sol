// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {LightPad} from "src/LP.sol";
import {LightPadToken} from "src/LightPadToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract LightPadTest is Test {
    event NewProjectCreated(uint256 projectId);

    uint256 pegasusFork;
    string PEGASUS_RPC_URL = vm.envString("PEGASUS_RPC_URL");

    // An IDO Setup
    string constant PROJECT_NAME = "TC Protocol";
    uint256 constant PRICE_PER_TOKEN = 0.02 ether;
    uint256 constant TOTAL_RAISE = 200000 ether;
    uint256 constant WHITELIST_NUMBER = 200;
    uint256 constant FIRST_IDO_ID = 0;

    LightPad lightPad;
    LightPadToken lightPadToken;
    ERC20Mock mockUsdc;
    ERC20Mock projectToken;

    address airnode = 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
    address owner = makeAddr("owner");

    function setUp() external {
        pegasusFork = vm.createFork(PEGASUS_RPC_URL);
        vm.selectFork(pegasusFork);

        lightPad = new LightPad(owner, airnode, address(lightPadToken));
        mockUsdc = new ERC20Mock();
        projectToken = new ERC20Mock();
    }

    function test_can_createProject() public {
        vm.expectEmit();
        emit NewProjectCreated(FIRST_IDO_ID);
        _owner_createProject();
    }

    function test_can_depositAllocation() public {}

    function _owner_createProject() internal {
        vm.prank(owner);
        lightPad.createProject(
            PROJECT_NAME, PRICE_PER_TOKEN, address(mockUsdc), TOTAL_RAISE, address(projectToken), WHITELIST_NUMBER
        );
    }

    function _owner_depositAllocation() public {
        vm.startPrank(owner);
        uint256 totalTokensInWhitelist = lightPad.getTotalTokenAllocation(FIRST_IDO_ID);
        projectToken.mint(owner, totalTokensInWhitelist);
        vm.stopPrank();
    }
}
