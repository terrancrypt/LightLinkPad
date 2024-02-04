// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RrpRequesterV0} from "@airnode/packages/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ILightPad} from "./interfaces/ILightPad.sol";

contract LightPad is ILightPad, Ownable, RrpRequesterV0 {
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    ERC20 private immutable i_lightPadToken;

    mapping(uint256 id => ProjectInfor) internal s_projectInfor;
    mapping(uint256 id => bool) private s_isProject;
    uint256 private s_projectCount;
    mapping(uint256 id => Phase) private s_projectPhase;
    mapping(uint256 projectId => PurchaseInfor) private s_purchaseInfor;

    // API3
    address private s_airnode;
    bytes32 private s_endpointIdUint256Array;
    address private s_sponsorWallet;
    mapping(bytes32 requestId => uint256 projectId) private s_requestIdToProject;
    mapping(bytes32 requestId => bool isFulfilled) private s_expectingRequestFulfilled;

    uint8 public constant STAKE_PHASE = 1;
    uint8 public constant WHITELIST_PHASE = 2;
    uint8 public constant PURCHASE_PHASE = 3;
    uint256 public constant STAKE_REQUIRE = 100e18; // Only relative and will change in the future.

    constructor(address _owner, address _airnodeRrp, address _lightPadToken)
        RrpRequesterV0(_airnodeRrp)
        Ownable(_owner)
    {
        i_lightPadToken = ERC20(_lightPadToken);
    }

    // Modifier
    modifier checkPhaseOnTime(uint256 _projectId, uint8 _currentPhase) {
        if (s_projectPhase[_projectId].currentPhase != _currentPhase) {
            revert ILightPad__PhaseNotOnTime(_projectId, _currentPhase);
        }

        if (
            s_projectPhase[_projectId].phaseDuration[_currentPhase]
                < block.timestamp - s_projectPhase[_projectId].phaseStartTime[_currentPhase]
        ) {
            revert ILightPad__PhaseNotOnTime(_projectId, _currentPhase);
        }
        _;
    }

    // Owner Setting
    function createProject(
        string memory _name,
        uint256 _pricePerToken,
        address _stablecoin,
        uint256 _totalRaise,
        address _tokenAddr,
        uint256 _whitelistNumber
    ) public onlyOwner {
        ProjectInfor storage project = s_projectInfor[s_projectCount];
        project.name = _name;
        project.pricePerToken = _pricePerToken;
        project.totalRaise = _totalRaise;
        project.stablecoin = _stablecoin;
        project.tokenAddr = _tokenAddr;
        project.whiteListNumber = _whitelistNumber;
        s_isProject[s_projectCount] = true;
        s_projectCount++;

        emit NewProjectCreated(s_projectCount - 1);
    }

    function depositAllocation(uint256 _projectId, uint256 _amount) public onlyOwner {
        s_projectInfor[_projectId].allocationBalance += _amount;

        address tokenAddr = s_projectInfor[_projectId].tokenAddr;
        ERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposited(_projectId, tokenAddr, _amount);
    }

    function startPad(uint256 _projectId) public onlyOwner {
        Phase storage phase = s_projectPhase[_projectId];

        /// 4 phase with phase duration automation setup, phase 4 has not duration time
        phase.phaseDuration[STAKE_PHASE] = 14 days;
        phase.phaseDuration[WHITELIST_PHASE] = 7 days;
        phase.phaseDuration[PURCHASE_PHASE] = 1 days;
        phase.phaseStartTime[STAKE_PHASE] = block.timestamp;
        phase.currentPhase = STAKE_PHASE; // get into phase 1;

        s_projectInfor[_projectId].isLive = true;

        emit PadStarted(_projectId);
    }

    function switchPhase(uint256 _projectId, uint8 _currentPhase, uint8 _nextPhase)
        public
        onlyOwner
        checkPhaseOnTime(_projectId, _currentPhase)
    {
        Phase storage phase = s_projectPhase[_projectId];
        phase.currentPhase = _nextPhase;

        emit PhaseSwitched(_projectId, _nextPhase);
    }

    function setRequestParameters(address _airnode, bytes32 _endpointIdUint256Array, address _sponsorWallet)
        public
        onlyOwner
    {
        s_airnode = _airnode;
        s_endpointIdUint256Array = _endpointIdUint256Array;
        s_sponsorWallet = _sponsorWallet;
    }

    function getWhiteList(uint256 _projectId) public onlyOwner checkPhaseOnTime(_projectId, WHITELIST_PHASE) {
        uint256 size = s_projectInfor[_projectId].whiteListNumber;

        bytes32 requestId = airnodeRrp.makeFullRequest(
            s_airnode,
            s_endpointIdUint256Array,
            address(this),
            s_sponsorWallet,
            address(this),
            this.fulfillRandomWhiteList.selector,
            // Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), size)
        );

        s_requestIdToProject[requestId] = _projectId;
        s_expectingRequestFulfilled[requestId] = true;

        emit RequestRandomForWhiteList(_projectId, requestId);
    }

    function fulfillRandomWhiteList(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        if (s_expectingRequestFulfilled[requestId]) {
            revert ILightPad__RequestInvalid(requestId);
        }

        s_expectingRequestFulfilled[requestId] = false;

        uint256 projectId = s_requestIdToProject[requestId];
        ProjectInfor storage project = s_projectInfor[projectId];
        uint256 userLength = project.user.length();
        uint256[] memory qrngUint256Array = abi.decode(data, (uint256[]));

        for (uint256 i; i < qrngUint256Array.length; i++) {
            uint256 whiteListIndex = (qrngUint256Array[i] % userLength) + 1;
            project.whitelist.add(project.user.at(whiteListIndex));
        }

        emit WhitelistGetted(projectId);
    }

    // User functions
    function stake(uint256 _projectId, uint256 _amount) public checkPhaseOnTime(_projectId, STAKE_PHASE) {
        if (_amount < STAKE_REQUIRE) {
            revert ILightPad__StakeNotEnough(_amount);
        }

        ProjectInfor storage project = s_projectInfor[_projectId];
        if (project.user.contains(msg.sender)) {
            revert ILightPad__AlreadyStake(_projectId, msg.sender);
        }

        project.user.add(msg.sender);
        i_lightPadToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(_projectId, _amount);
    }

    function purchase(uint256 _projectId) public checkPhaseOnTime(_projectId, PURCHASE_PHASE) {
        address user = msg.sender;
        ProjectInfor storage project = s_projectInfor[_projectId];
        PurchaseInfor storage purchaseInfor = s_purchaseInfor[_projectId];

        if (!project.whitelist.contains(user)) {
            revert ILightPad__NotInWhiteList(_projectId);
        }
        if (purchaseInfor.isPurchased[user] == true) {
            revert ILightPad__AlreadyPurchase(_projectId, user);
        }

        uint256 amountPerWhitelist = _calAmountPerWhitelist(project.totalRaise, project.whiteListNumber);
        uint256 allocation = _calTokensPerWhitelist(amountPerWhitelist, project.pricePerToken);

        purchaseInfor.isPurchased[user] = true;
        purchaseInfor.allocation[user] = allocation;

        ERC20(project.stablecoin).safeTransferFrom(user, address(this), amountPerWhitelist);

        emit Purchased(_projectId, user);
    }

    function claim(uint256 _projectId) public {
        address user = msg.sender;
        ProjectInfor storage project = s_projectInfor[_projectId];
        PurchaseInfor storage purchaseInfor = s_purchaseInfor[_projectId];

        uint256 allocation = purchaseInfor.allocation[user];

        if (allocation <= 0) {
            revert ILightPad__InsufficientBalance(_projectId, user);
        }

        purchaseInfor.allocation[user] = 0;

        ERC20(project.tokenAddr).safeTransfer(user, allocation);

        emit Claimed(_projectId, user);
    }

    // Internal functions
    function _calAmountPerWhitelist(uint256 _totalRaise, uint256 _whiteListNumber) internal pure returns (uint256) {
        uint256 amountPerWhitelist = _totalRaise / _whiteListNumber;
        return amountPerWhitelist;
    }

    function _calTokensPerWhitelist(uint256 amountPerWhitelist, uint256 pricePertoken)
        internal
        pure
        returns (uint256)
    {
        uint256 tokensPerWhitelist = amountPerWhitelist / pricePertoken;
        return tokensPerWhitelist;
    }

    function _calTotalTokenAllcation(uint256 _projectId) internal view returns (uint256) {
        uint256 totalRaise = s_projectInfor[_projectId].totalRaise;
        uint256 whiteListNumber = s_projectInfor[_projectId].whiteListNumber;
        uint256 pricePerToken = s_projectInfor[_projectId].pricePerToken;
        uint256 amountPerWhitelist = _calAmountPerWhitelist(totalRaise, whiteListNumber);
        uint256 tokensPerWhitelist = _calTokensPerWhitelist(amountPerWhitelist, pricePerToken);
        uint256 totalTokensInWhitelist = tokensPerWhitelist * whiteListNumber;
        return totalTokensInWhitelist;
    }

    // Getter functions
    function getTotalTokenAllocation(uint256 _projectId) public view returns (uint256) {
        return _calTotalTokenAllcation(_projectId);
    }

    function getProjectInfo(uint256 _projectId)
        public
        view
        returns (
            bool isLive,
            string memory name,
            address tokenAddr,
            uint256 pricePerToken,
            uint256 totalRaise,
            address stablecoin,
            uint256 allocationBalance,
            uint256 whiteListNumber
        )
    {
        ProjectInfor storage project = s_projectInfor[_projectId];
        return (
            project.isLive,
            project.name,
            project.tokenAddr,
            project.pricePerToken,
            project.totalRaise,
            project.stablecoin,
            project.allocationBalance,
            project.whiteListNumber
        );
    }

    function getWhitelist(uint256 _projectId) public view returns (address[] memory) {
        ProjectInfor storage project = s_projectInfor[_projectId];
        return project.whitelist.values();
    }

    function getIsUserStaked(uint256 _projectId, address user) public view returns (bool) {
        ProjectInfor storage project = s_projectInfor[_projectId];
        return project.user.contains(user);
    }

    function getUserList(uint256 _projectId) public view returns (address[] memory) {
        ProjectInfor storage project = s_projectInfor[_projectId];
        return project.user.values();
    }

    function getAllocationBalance(uint256 _projectId) public view returns (uint256) {
        return s_projectInfor[_projectId].allocationBalance;
    }

    function getCurrentPhase(uint256 _projectId) public view returns (uint64) {
        return s_projectPhase[_projectId].currentPhase;
    }

    function isUserStaked(uint256 _projectId, address _user) public view returns (bool) {
        return s_projectInfor[_projectId].user.contains(_user);
    }

    function getUserStakeNumber(uint256 _projectId, address _user) public view returns (uint256) {
        return s_projectInfor[_projectId].stakeNumber[_user];
    }

    function getPurchaseInfo(uint256 _projectId, address _user)
        public
        view
        returns (bool isPurchased, uint256 allocation)
    {
        PurchaseInfor storage purchaseInfo = s_purchaseInfor[_projectId];
        return (purchaseInfo.isPurchased[_user], purchaseInfo.allocation[_user]);
    }

    function getProjectPhase(uint256 _projectId) public view returns (uint64 currentPhase) {
        return s_projectPhase[_projectId].currentPhase;
    }
}
