// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ILightPad {
    error ILightPad__PhaseNotOnTime(uint256 projectId, uint256 currentPhase);
    error ILightPad__RequestInvalid(bytes32 requetsId);
    error ILightPad__StakeNotEnough(uint256 amount);
    error ILightPad__AlreadyStake(uint256 projectId, address user);

    event NewProjectCreated(uint256 projectId);
    event Deposited(uint256 indexed projectId, address tokenAddr, uint256 amount);
    event PadStarted(uint256 indexed projectId);
    event PhaseSwitched(uint256 projectId, uint8 nextPhase);
    event Staked(uint256 indexed projectId, uint256 amount);
    event RequestRandomForWhiteList(uint256 projectId, bytes32 requestId);
    event WhitelistGetted(uint256 projectId);

    struct ProjectInfor {
        bool isLive;
        string name;
        address tokenAddr;
        uint256 pricePerToken;
        uint256 totalRaise; // in stablecoin
        address stablecoin;
        uint256 allocationBalance;
        uint256 whiteListNumber;
        EnumerableSet.AddressSet whitelist;
        EnumerableSet.AddressSet user;
        mapping(address user => uint256 stakeNumber) stakeNumber;
    }

    struct Phase {
        mapping(uint64 phase => uint256 duration) phaseDuration;
        mapping(uint64 phase => uint256 startTime) phaseStartTime;
        uint64 currentPhase;
    }
}
