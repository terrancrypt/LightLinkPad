// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LightPad} from "./LightPad.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PaginationProcessing is Ownable {
    LightPad immutable i_lightPad;

    struct Pagination {
        uint256 currentStartIndex;
        uint256 currentEndIndex;
        uint64 currentPage;
    }

    mapping(uint256 idoId => Pagination) private s_idoToPagination;

    uint256 constant ADDRESS_PER_PAGE = 100; // Can change in the futures by calculate;

    constructor(address _owner, address _lightPad) Ownable(_owner) {
        i_lightPad = LightPad(_lightPad);
    }

    function tierDivision(uint256 _idoId) public onlyOwner {}

    function _getPagination(
        uint256 _idoId
    ) internal returns (uint256 startIndex, uint256 endIndex) {
        uint256 numberOfStakers = i_lightPad.getNumberIDOStakers(_idoId);
        Pagination storage pagination = s_idoToPagination[_idoId];
        if (numberOfStakers <= ADDRESS_PER_PAGE) {
            startIndex = 0;
            endIndex = numberOfStakers;
        } else {
            startIndex = currentPage * ADDRESS_PER_PAGE;
            endIndex = start + ADDRESS_PER_PAGE;

            pagination.currentStartIndex = startIndex;
            pagination.currentEndIndex = endIndex;
        }

        pagination.currentPage++;
    }
}
