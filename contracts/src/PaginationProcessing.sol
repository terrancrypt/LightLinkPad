// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {LightPad} from "./LightPad.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PaginationProcessing is Ownable {
    error PaginationProcessing_IDOIsNotExists();
    error PaginationProcessing_IDOIsNotOpen();
    error PaginationProcessing_PhaseIsNotOnTime();

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

    function tierDivision(uint256 _idoId) public onlyOwner {
        if (i_lightPad.getIDOExist(_idoId) == false) {
            revert PaginationProcessing_IDOIsNotExists();
        }
        if (i_lightPad.getIsIdoOpen(_idoId) == false) {
            revert PaginationProcessing_IDOIsNotOpen();
        }
        if (i_lightPad.getIDOPhaseOnTime(_idoId, i_lightPad.TIER_PHASE()) == false) {
            revert PaginationProcessing_PhaseIsNotOnTime();
        }

        (uint256 startIndex, uint256 endIndex) = _getPagination(_idoId);

        for (uint256 i = startIndex; i <= endIndex; i++) {
            i_lightPad.tierDivision(_idoId, i);
        }
    }

    function _getPagination(uint256 _idoId) internal returns (uint256 startIndex, uint256 endIndex) {
        uint256 numberOfStakers = i_lightPad.getNumberIDOStakers(_idoId);
        Pagination storage pagination = s_idoToPagination[_idoId];
        if (numberOfStakers <= ADDRESS_PER_PAGE) {
            startIndex = 0;
            endIndex = numberOfStakers;
        } else {
            startIndex = pagination.currentPage * ADDRESS_PER_PAGE;
            endIndex = startIndex + ADDRESS_PER_PAGE;

            pagination.currentStartIndex = startIndex;
            pagination.currentEndIndex = endIndex;
        }
    }

    function _increaseCurrentPage(uint256 _idoId) internal {
        s_idoToPagination[_idoId].currentPage++;
    }
}
