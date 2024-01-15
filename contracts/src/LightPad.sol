// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {RrpRequesterV0} from "@airnode/packages/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LightPad is RrpRequesterV0, Ownable {
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
        mapping(uint64 phase => uint256 duration) phaseDuration;
        mapping(uint64 phase => uint256 startTime) phaseStartTime;
        uint64 currentPhase;
    }
    mapping(uint256 id => IDOInfor) private s_IDOInformation;
    uint256 private s_IDOCount;

    struct Staker {
        mapping(uint256 stakeId => mapping(uint256 stakeTime => uint256 amount)) stakeInfor;
        uint256 numberOfStake;
    }
    mapping(address staker => mapping(uint256 projectId => Staker))
        private s_stakers;

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
        IDOInfor storage idoInfor = s_IDOInformation[_idoId];
        idoInfor.isOpen = true;
        idoInfor.currentPhase = 1;
        idoInfor.phaseStartTime[idoInfor.currentPhase] = block.timestamp;

        emit IDOStart(_idoId);
    }
}
