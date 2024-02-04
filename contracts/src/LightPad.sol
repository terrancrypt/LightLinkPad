// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {RrpRequesterV0} from "@airnode/packages/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract LightPad is RrpRequesterV0, ReentrancyGuard, AccessControl {
    // ========== Error ==========
    error LightPad_IDOIsNotExists();
    error LightPad_MustNotBeZero();
    error LightPad_IDOIsNotOpen(uint256 idoId);
    error LightPad_PhaseIsNotOnTime();
    error LightPad_PhaseIsOnTime(uint256 idoId, uint64 phase);
    error LightPad_CannotStakeMore();

    // ========== Types ==========
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ========== State Variables ==========
    ERC20 private immutable i_lightPadToken; // Light Pad Token

    address public airnode;
    bytes32 public endpointIdUint256Array;
    address public sponsorWallet;

    struct IDOInfor {
        bool isOpen; // Dự án đã được mở bán hay chưa?
        bool isEnded; // Dự án đã kết thúc hay chưa?
        string projectName; // Tên của dự án
        address tokenAddr; // Địa chỉ mã thông báo được phát hành
        uint256 pricePerToken; // Gía của mỗi token
        uint256 totalRaise; // Số lượng token tối đa được phát hành
    }

    mapping(uint256 id => IDOInfor) private s_IDOInformation;
    mapping(uint256 id => bool) private s_isIDOExists;
    uint256 private s_IDOCount;

    struct IDOPhase {
        mapping(uint64 phase => uint256 duration) phaseDuration;
        mapping(uint64 phase => uint256 startTime) phaseStartTime;
        uint64 currentPhase;
    }

    mapping(uint256 id => IDOPhase) private s_IDOPhase;

    struct Staker {
        mapping(uint256 stakeId => uint256 stakeTime) stakeTime;
        mapping(uint256 stakeTime => uint256 amount) amountOnce;
        uint256 totalAmount;
        uint256 numberOfStake;
    }

    mapping(address staker => mapping(uint256 projectId => Staker)) private s_stakers;

    mapping(uint256 idoId => EnumerableSet.AddressSet) private s_idoToStaker;

    struct IDOAllocation {
        mapping(address user => uint256 amount) remainingAmount;
        EnumerableSet.AddressSet whitelist;
        EnumerableSet.AddressSet guaranteedAllocation;
        uint256 totalUserWeight;
        uint256 allocatedQuantity;
    }

    mapping(uint256 idoId => IDOAllocation) private s_idoAllocation;

    uint64 public constant STAKE_PHASE = 1;
    uint64 public constant TIER_PHASE = 2;
    uint64 public constant PURCHASE_PHASE = 3;
    uint64 public constant MAXIMUM_STAKE = 5;
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    constructor(address _owner, address _airnodeRrp, address _lightPadToken, address _paginationProcessing)
        RrpRequesterV0(_airnodeRrp)
    {
        i_lightPadToken = ERC20(_lightPadToken);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MODERATOR_ROLE, _paginationProcessing);
    }

    // ========== Events ==========
    event NewIDOAdded(uint256 id);
    event IDOStart(uint256 id);
    event IDOUpdated(uint256 id);
    event TokenSaleOpened(uint256 id);
    event StakeToIDO(address user, uint256 amount, uint256 idoId);
    event SwitchToTierPhase(uint256 idoId, uint256 startTime);
    event TierDivision(uint256 idoId, uint256 startIndex, uint256 endIndex);

    // ========== Modfiers ==========
    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyModerator() {
        _checkRole(MODERATOR_ROLE);
        _;
    }

    // ========== API3 QRNG Functions ==========
    function setAPI3RequestParameters(address _airnode, bytes32 _endpointIdUint256Array, address _sponsorWallet)
        external
        onlyOwner
    {
        airnode = _airnode;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsorWallet = _sponsorWallet;
    }

    // ========== Owner functions ==========
    function createIDO(string memory _projectName, address _tokenAddr, uint256 _pricePerToken, uint256 _totalRaise)
        public
        onlyOwner
    {
        IDOInfor storage idoInfor = s_IDOInformation[s_IDOCount];
        idoInfor.projectName = _projectName;
        idoInfor.tokenAddr = _tokenAddr;
        idoInfor.pricePerToken = _pricePerToken;
        idoInfor.totalRaise = _totalRaise;
        s_isIDOExists[s_IDOCount] = true;
        s_IDOCount++;

        emit NewIDOAdded(s_IDOCount - 1);
    }

    function updateIDO(
        uint256 _idoId,
        string memory _projectName,
        address _tokenAddr,
        uint256 _pricePerToken,
        uint256 _totalRaise
    ) public onlyOwner {
        IDOInfor storage idoInfor = s_IDOInformation[_idoId];
        idoInfor.projectName = _projectName;
        idoInfor.tokenAddr = _tokenAddr;
        idoInfor.pricePerToken = _pricePerToken;
        idoInfor.totalRaise = _totalRaise;

        emit IDOUpdated(_idoId);
    }

    function startIDO(uint256 _idoId) public onlyOwner {
        s_IDOInformation[_idoId].isOpen = true;
        IDOPhase storage phase = s_IDOPhase[_idoId];

        /// 4 phase with phase duration automation setup, phase 4 has not duration time
        phase.phaseDuration[STAKE_PHASE] = 14 days; // Stake
        phase.phaseDuration[TIER_PHASE] = 2 days; // Tier Division
        phase.phaseDuration[PURCHASE_PHASE] = 1 days; // Purchase
        phase.phaseStartTime[STAKE_PHASE] = block.timestamp;
        phase.currentPhase = STAKE_PHASE; // get into phase 1;

        emit IDOStart(_idoId);
    }

    function switchToTierPhase(uint256 _idoId) public onlyOwner {
        if (!_isIDOExists(_idoId)) {
            revert LightPad_IDOIsNotExists();
        }
        if (s_IDOInformation[_idoId].isOpen = false) {
            revert LightPad_IDOIsNotOpen(_idoId);
        }
        if (_isIDOPhaseOnTime(_idoId, STAKE_PHASE)) {
            revert LightPad_PhaseIsOnTime(_idoId, STAKE_PHASE);
        }

        IDOPhase storage phase = s_IDOPhase[_idoId];

        phase.phaseStartTime[TIER_PHASE] = block.timestamp;
        phase.currentPhase = TIER_PHASE;

        emit SwitchToTierPhase(_idoId, block.timestamp);
    }

    function tierDivision(uint256 _idoId, uint256 userIndex) external onlyModerator {
        address user = s_idoToStaker[_idoId].at(userIndex);

        uint256 stakeAmount = _getTotalStakeAmount(user, _idoId);

        IDOAllocation storage allocation = s_idoAllocation[_idoId];

        if (stakeAmount > 1 ether && stakeAmount < 300 ether) {
            allocation.whitelist.add(user);
        } else if (stakeAmount >= 300 ether) {
            allocation.guaranteedAllocation.add(user);
            uint256 userWeight = _calculateUserWeight(user, _idoId);
            allocation.totalUserWeight += userWeight;
        }
    }

    function finishTierDivision() external onlyModerator {}

    function stake(uint256 _idoId, uint256 amount) public nonReentrant {
        if (!_isIDOExists(_idoId)) {
            revert LightPad_IDOIsNotExists();
        }
        if (amount <= 0) {
            revert LightPad_MustNotBeZero();
        }
        if (s_IDOInformation[_idoId].isOpen = false) {
            revert LightPad_IDOIsNotOpen(_idoId);
        }
        if (!_isIDOPhaseOnTime(_idoId, STAKE_PHASE)) {
            revert LightPad_PhaseIsNotOnTime();
        }

        Staker storage stakeInfor = s_stakers[msg.sender][_idoId];

        // This is intended to protect against DoS attacks.
        if (stakeInfor.numberOfStake > MAXIMUM_STAKE) {
            revert LightPad_CannotStakeMore();
        }

        stakeInfor.stakeTime[stakeInfor.numberOfStake] = block.timestamp;
        stakeInfor.amountOnce[block.timestamp] = amount;
        stakeInfor.totalAmount += amount;
        stakeInfor.numberOfStake++;
        s_idoToStaker[_idoId].add(msg.sender);

        i_lightPadToken.safeTransferFrom(msg.sender, address(this), amount);

        emit StakeToIDO(msg.sender, amount, _idoId);
    }

    // ========== Internal Functions ==========
    function _isIDOExists(uint256 _idoId) internal view returns (bool) {
        return s_isIDOExists[_idoId];
    }

    function _isIDOPhaseOnTime(uint256 _idoId, uint64 _currentPhase) internal view returns (bool) {
        if (s_IDOPhase[_idoId].currentPhase != _currentPhase) {
            return false;
        }

        if (
            s_IDOPhase[_idoId].phaseDuration[_currentPhase]
                < block.timestamp - s_IDOPhase[_idoId].phaseStartTime[_currentPhase]
        ) {
            return false;
        }

        return true;
    }

    function _getTotalStakeAmount(address _staker, uint256 _idoId) internal view returns (uint256) {
        return s_stakers[_staker][_idoId].totalAmount;
    }

    function _calculateAverageStakeAmount(address _staker, uint256 _idoId) internal view returns (uint256) {
        uint256 totalStakeAmount = _getTotalStakeAmount(_staker, _idoId);

        return totalStakeAmount / s_stakers[_staker][_idoId].numberOfStake;
    }

    function _caculateAverageStakeTime(address _staker, uint256 _idoId) internal view returns (uint256) {
        Staker storage staker = s_stakers[_staker][_idoId];
        uint256 totalStakeTime = 0;

        for (uint256 i; i <= staker.numberOfStake; i++) {
            uint256 stakeTime = staker.stakeTime[i];

            if (stakeTime > 0) {
                totalStakeTime += block.timestamp - stakeTime;
            }
        }

        if (staker.numberOfStake > 0) {
            return totalStakeTime / staker.numberOfStake;
        } else {
            return 0;
        }
    }

    function _calculateUserWeight(address _staker, uint256 _idoId) internal view returns (uint256) {
        uint256 avgStakeAmount = _calculateAverageStakeAmount(_staker, _idoId);
        uint256 avgStakeTime = _caculateAverageStakeTime(_staker, _idoId);

        return (avgStakeAmount / 1e18) * avgStakeTime;
    }

    function _caculateAllocation(address _staker, uint256 _idoId) internal view returns (uint256) {
        uint256 userWeight = _calculateUserWeight(_staker, _idoId);
        uint256 totalUserWeight = s_idoAllocation[_idoId].totalUserWeight;
        uint256 totalRaise = s_IDOInformation[_idoId].totalRaise;

        uint256 allocation = (userWeight / totalUserWeight) * totalRaise;
        return allocation;
    }

    // =========== Getter Functions =========
    function getIDOCount() external view returns (uint256) {
        return s_IDOCount;
    }

    function getIDOInfor(uint256 _idoId) external view returns (IDOInfor memory) {
        return s_IDOInformation[_idoId];
    }

    function getIsIdoOpen(uint256 _idoId) external view returns (bool) {
        return s_IDOInformation[_idoId].isOpen;
    }

    function getIDOCurrentPhase(uint256 _idoId) external view returns (uint64) {
        return s_IDOPhase[_idoId].currentPhase;
    }

    function getIDOExist(uint256 _idoId) external view returns (bool) {
        return _isIDOExists(_idoId);
    }

    function getIDOPhaseOnTime(uint256 _idoId, uint64 _currentPhase) external view returns (bool) {
        return _isIDOPhaseOnTime(_idoId, _currentPhase);
    }

    function getTotalStakeAmount(address _staker, uint256 _idoId) external view returns (uint256) {
        return _getTotalStakeAmount(_staker, _idoId);
    }

    function getAverageStakeAmount(address _staker, uint256 _idoId) public view returns (uint256) {
        return _calculateAverageStakeAmount(_staker, _idoId);
    }

    function getAverageStakeTime(address _staker, uint256 _idoId) external view returns (uint256) {
        return _caculateAverageStakeTime(_staker, _idoId);
    }

    function getUserWeight(address _staker, uint256 _idoId) external view returns (uint256) {
        return _calculateUserWeight(_staker, _idoId);
    }

    function getAllocation(address _staker, uint256 _idoId) external view returns (uint256) {
        return _caculateAllocation(_staker, _idoId);
    }

    function getTimeStamp() external view returns (uint256) {
        return block.timestamp;
    }

    function getNumberIDOStakers(uint256 _idoId) external view returns (uint256) {
        return s_idoToStaker[_idoId].length();
    }
}
