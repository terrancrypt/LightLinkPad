// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {RrpRequesterV0} from "lib/airnode/packages/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LightPad is RrpRequesterV0, Ownable {
    // ========== Types ==========
    using SafeERC20 for ERC20;

    // ========== State Variables ==========
    ERC20 private immutable i_lightPadToken; // Light Pad Token
    address public airnode;
    bytes32 public endpointIdUint256Array;
    address public sponsorWallet;

    struct ProjectInfor {
        bool isOpen; // Dự án đã được mở bán hay chưa?
        bool isEnded; // Dự án đã kết thúc hay chưa?
        string projectName; // Tên của dự án
        address tokenAddr; // Địa chỉ mã thông báo được phát hành
        uint256 pricePerToken; // Gía của mỗi token
        uint256 maxTokensAvailable; // Số lượng token tối đa được phát hành
        uint256 whitelistLimit; // Số lượng người có thể mua được token
        address[] investors; // Danh sách số lượng người đã tham gia lauchpad
    }
    mapping(uint256 projectId => ProjectInfor) private s_projectInformation;
    uint256 private s_projectCount;

    constructor(
        address _owner,
        address _airnodeRrp,
        address _lightPadToken
    ) Ownable(_owner) RrpRequesterV0(_airnodeRrp) {
        i_lightPadToken = ERC20(_lightPadToken);
    }

    // ========== Events ==========
    event NewLauchPadCreated(ProjectInfor);
    event TokenSaleOpened(uint256 projectId);

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

    function createLaunchPad(
        ProjectInfor memory projectInfor
    ) external onlyOwner {
        s_projectInformation[s_projectCount] = projectInfor;
        s_projectCount++;

        emit NewLauchPadCreated(projectInfor);
    }

    function openProjectForSale(uint256 projectId) public onlyOwner {
        s_projectInformation[projectId].isOpen = true;

        emit TokenSaleOpened(projectId);
    }

    function enterLaunchPad(uint256 projectId) external {
        ProjectInfor memory projectInfor = s_projectInformation[projectId];

        i_lightPadToken.safeTransferFrom(
            msg.sender,
            address(this),
            projectInfor.pricePerToken
        );
    }
}
