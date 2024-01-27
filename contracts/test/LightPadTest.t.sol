// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {LightPad} from "src/LightPad.sol";
import {LightPadToken} from "src/LightPadToken.sol";
import {PaginationProcessing} from "src/PaginationProcessing.sol";

contract LightPadTest is Test {
    uint256 pegasusFork;
    string PEGASUS_RPC_URL = vm.envString("PEGASUS_RPC_URL");

    LightPad lightPad;
    LightPadToken lightPadToken;
    PaginationProcessing paginationProcessing;

    address owner = makeAddr("owner");
    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    // An IDO Setup
    string constant PROJECT_NAME = "TC Protocol";
    address PROJECT_ADDRESS = makeAddr("Tc Protocol");
    uint256 constant PRICE_PER_TOKEN = 0.02 ether;
    uint256 constant TOTAL_RAISE = 200000 ether;
    uint256 constant FIRST_IDO_ID = 0;

    function setUp() external {
        pegasusFork = vm.createFork(PEGASUS_RPC_URL);
        vm.selectFork(pegasusFork);

        vm.startBroadcast();
        lightPadToken = new LightPadToken();
        lightPad = new LightPad(
            owner,
            0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd,
            address(lightPadToken),
            address(paginationProcessing)
        );
        vm.stopBroadcast();

        vm.prank(user);
        lightPadToken.faucet();
        vm.prank(user2);
        lightPadToken.faucet();
    }

    modifier owner_create_ido() {
        vm.prank(owner);
        lightPad.createIDO(
            PROJECT_NAME,
            PROJECT_ADDRESS,
            PRICE_PER_TOKEN,
            TOTAL_RAISE
        );
        _;
    }

    modifier owner_start_ido() {
        vm.warp(block.timestamp);
        vm.prank(owner);
        lightPad.startIDO(FIRST_IDO_ID);
        _;
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

    function test_can_startIdo() public owner_create_ido {
        vm.warp(block.timestamp);
        vm.prank(owner);
        lightPad.startIDO(FIRST_IDO_ID);

        uint64 currentPhase = lightPad.getIDOCurrentPhase(FIRST_IDO_ID);
        bool isPhaseOnTime = lightPad.getIDOPhaseOnTime(
            FIRST_IDO_ID,
            lightPad.STAKE_PHASE()
        );

        assertEq(currentPhase, lightPad.STAKE_PHASE());
        assertEq(isPhaseOnTime, true);

        vm.warp(block.timestamp + 15 days);
        vm.roll(100);

        bool isPhaseOnTime2nd = lightPad.getIDOPhaseOnTime(
            FIRST_IDO_ID,
            lightPad.STAKE_PHASE()
        );

        assertEq(isPhaseOnTime2nd, false);
    }

    function test_can_switchToTierPhase()
        public
        owner_create_ido
        owner_start_ido
    {
        vm.warp(block.timestamp + 15 days);
        vm.roll(100);
        vm.prank(owner);
        lightPad.switchToTierPhase(FIRST_IDO_ID);

        uint64 currentPhase = lightPad.getIDOCurrentPhase(FIRST_IDO_ID);
        bool isTierPhaseOnTime = lightPad.getIDOPhaseOnTime(
            FIRST_IDO_ID,
            lightPad.TIER_PHASE()
        );

        assertEq(currentPhase, lightPad.TIER_PHASE());
        assertEq(isTierPhaseOnTime, true);
    }

    function test_can_stake() public owner_create_ido owner_start_ido {
        vm.warp(block.timestamp + 4 days);
        vm.roll(30);
        uint256 firstTimeStake = lightPad.getTimeStamp();
        console.log("Time of user stake first time: ", firstTimeStake);

        vm.startPrank(user);
        lightPadToken.approve(address(lightPad), lightPadToken.FAUCET_AMOUNT());
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT());
        vm.stopPrank();

        uint256 totalStakeAmount = lightPad.getTotalStakeAmount(
            user,
            FIRST_IDO_ID
        );

        assertEq(totalStakeAmount, lightPadToken.FAUCET_AMOUNT());

        vm.warp(block.timestamp + 6 days);
        vm.roll(60);

        uint256 timeCheckAvgStake = lightPad.getTimeStamp();
        console.log("Time of user stake first time: ", timeCheckAvgStake);

        uint256 expectedAvgStakeTime = (timeCheckAvgStake - firstTimeStake) / 1;
        uint256 averageStakeTime = lightPad.getAverageStakeTime(
            user,
            FIRST_IDO_ID
        );

        assertEq(expectedAvgStakeTime, averageStakeTime);
    }

    function test_can_getAverageStakeAmount()
        public
        owner_create_ido
        owner_start_ido
    {
        vm.warp(block.timestamp + 4 days);
        vm.roll(30);

        vm.startPrank(user);
        lightPadToken.approve(address(lightPad), lightPadToken.FAUCET_AMOUNT());
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT());
        vm.stopPrank();

        vm.startPrank(user);
        lightPadToken.faucet();
        lightPadToken.approve(
            address(lightPad),
            lightPadToken.FAUCET_AMOUNT() - 50e18
        );
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT() - 50e18);
        vm.stopPrank();

        uint256 avgStakeAmount = lightPad.getAverageStakeAmount(
            user,
            FIRST_IDO_ID
        );

        console.log(avgStakeAmount);
    }

    function test_can_getUserWeight() public owner_create_ido owner_start_ido {
        vm.warp(block.timestamp + 4 days);
        vm.roll(30);

        vm.startPrank(user);
        lightPadToken.approve(address(lightPad), lightPadToken.FAUCET_AMOUNT());
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT());
        vm.stopPrank();

        vm.startPrank(user);
        lightPadToken.faucet();
        lightPadToken.approve(
            address(lightPad),
            lightPadToken.FAUCET_AMOUNT() - 50e18
        );
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT() - 50e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 6 days);
        vm.roll(60);

        uint256 avgStakeAmount = lightPad.getAverageStakeAmount(
            user,
            FIRST_IDO_ID
        );
        uint256 avgStakeTime = lightPad.getAverageStakeTime(user, FIRST_IDO_ID);

        console.log(avgStakeAmount);
        console.log(avgStakeTime);

        uint256 userWeight = lightPad.getUserWeight(user, FIRST_IDO_ID);

        console.log(userWeight);
    }

    function test_getUserWeight_for_2_user()
        public
        owner_create_ido
        owner_start_ido
    {
        vm.warp(block.timestamp + 4 days);
        vm.roll(30);

        vm.startPrank(user);
        lightPadToken.approve(address(lightPad), lightPadToken.FAUCET_AMOUNT());
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT());
        vm.stopPrank();

        vm.warp(block.timestamp + 6 days);
        vm.roll(30);

        vm.startPrank(user2);
        lightPadToken.faucet();
        lightPadToken.approve(address(lightPad), lightPadToken.FAUCET_AMOUNT());
        lightPad.stake(FIRST_IDO_ID, lightPadToken.FAUCET_AMOUNT());
        vm.stopPrank();

        vm.warp(block.timestamp + 8 days);
        vm.roll(30);

        uint256 user1Weight = lightPad.getUserWeight(user, FIRST_IDO_ID);
        uint256 user2Weight = lightPad.getUserWeight(user2, FIRST_IDO_ID);

        assert(user1Weight > user2Weight);
    }
}
