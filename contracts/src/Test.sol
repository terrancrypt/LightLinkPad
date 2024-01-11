// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract RandomWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Biến dùng để chứa số lượng stake của một user, thời gian bắt đầu stake và số lượng stake

    // Người dùng stake từ 1 đến 199 token LPT
    EnumerableSet.AddressSet private regularStakers;
    // Người dùng stake trên 199 token LPT
    EnumerableSet.AddressSet private premiumStakers;

    // Danh sách whitelist sử dụng EnumerableSet để tránh trùng lặp
    EnumerableSet.AddressSet private whitelist;

    // Hàm để ghi thông tin của một project
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

    // Sự kiện thông báo khi có người dùng được thêm vào whitelist
    event UserAddedToWhitelist(address indexed user);

    // Hàm để đăng ký người dùng
    function registerUser(uint256 stakedAmount) external {
        if (!regularStakers.contains(user) && !premiumStakers.contains(user)) {
            if (stakedAmount >= 1 && stakedAmount <= 199) {
                regularStakers.add(msg.sender);
            } else if (stakedAmount > 199) {
                premiumStakers.add(msg.sender);
            }
        }

        // Gửi sự kiện thông báo
        emit UserAddedToWhitelist(msg.sender);
    }

    // Hàm để kiểm tra xem một địa chỉ có trong whitelist hay không
    function isUserInWhitelist(address user) external view returns (bool) {
        return whitelist.contains(user);
    }

    // Hàm để lấy số lượng người dùng đã đăng ký
    function getRegisteredUsersCount() external view returns (uint256) {
        return registeredUsers.length();
    }

    // Hàm để lấy số lượng người dùng trong whitelist
    function getWhitelistCount() external view returns (uint256) {
        return whitelist.length();
    }
}
