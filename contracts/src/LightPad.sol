// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {RrpRequesterV0} from "@airnode/packages/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LightPad is RrpRequesterV0, ReentrancyGuard, Ownable {
    // ========== Error ==========
    error LightPad_IDOIsNotExists();
    error LightPad_MustNotBeZero();
    error LightPad_IDOIsNotOpen(uint256 idoId);
    error LightPad_PhaseIsNotOnTime();
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
        mapping(uint256 stakeId => mapping(uint256 stakeTime => uint256 amount)) stakeInfor;
        uint256 numberOfStake;
    }
    mapping(address staker => mapping(uint256 projectId => Staker))
        private s_stakers;

    uint64 private constant STAKE_PHASE = 1;
    uint64 private constant TIER_PHASE = 2;
    uint64 private constant CLAIM_PHASE = 3;

    constructor(
        address _owner,
        address _airnodeRrp,
        address _lightPadToken
    ) Ownable(_owner) RrpRequesterV0(_airnodeRrp) {
        i_lightPadToken = ERC20(_lightPadToken);
    }

    // ========== Events ==========
    event NewIDOAdded(uint256 id);
    event IDOStart(uint256 id);
    event IDOUpdated(uint256 id);
    event TokenSaleOpened(uint256 id);
    event StakeToIDO(address user, uint256 amount, uint256 idoId);

    // ========== API3 QRNG Functions ==========
    function setAPI3RequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256Array,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsorWallet = _sponsorWallet;
    }

    // ========== Owner functions ==========
    function createIDO(
        string memory _projectName,
        address _tokenAddr,
        uint256 _pricePerToken,
        uint256 _totalRaise
    ) public onlyOwner {
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
        phase.phaseDuration[CLAIM_PHASE] = 1 days; // Purchase
        phase.currentPhase++; // get into phase 1;

        emit IDOStart(_idoId);
    }

    function stake(uint256 _idoId, uint256 amount) public {
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
        if (stakeInfor.numberOfStake > 5) {
            revert LightPad_CannotStakeMore();
        }

        stakeInfor.stakeInfor[stakeInfor.numberOfStake][
            block.timestamp
        ] = amount;
        stakeInfor.numberOfStake++;

        i_lightPadToken.safeTransferFrom(msg.sender, address(this), amount);

        emit StakeToIDO(msg.sender, amount, _idoId);
    }

    function _isIDOExists(uint256 _idoId) internal view returns (bool) {
        return s_isIDOExists[_idoId];
    }

    function _isIDOPhaseOnTime(
        uint256 _idoId,
        uint64 _currentPhase
    ) internal view returns (bool) {
        if (s_IDOPhase[_idoId].currentPhase != _currentPhase) {
            return false;
        }

        if (
            s_IDOPhase[_idoId].phaseDuration[_currentPhase] <
            block.timestamp - s_IDOPhase[_idoId].phaseStartTime[_currentPhase]
        ) {
            return false;
        }

        return true;
    }

    function getIDOInfor(
        uint256 _idoId
    ) external view returns (IDOInfor memory) {
        return s_IDOInformation[_idoId];
    }

    function getIDOCount() external view returns (uint256) {
        return s_IDOCount;
    }
}
