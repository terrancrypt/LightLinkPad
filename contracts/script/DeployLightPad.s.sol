// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {LightPad} from "src/LP.sol";
import {LightPadToken} from "src/LightPadToken.sol";

contract DeployLightPad is Script {
    LightPad lightPad;
    LightPadToken lightPadToken;
    uint256 privateKey;

    function run() external returns (LightPadToken, LightPad) {
        privateKey = convertStringToUint(vm.envString("PRIVATE_KEY"));

        vm.startBroadcast();
        lightPadToken = new LightPadToken();
        lightPad = new LightPad(
            0x7f4A3Fe909524CEa8C91fFdEf717C797581AE36D,
            0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd,
            address(lightPadToken)
        );
        vm.stopBroadcast();

        return (lightPadToken, lightPad);
    }

    function convertStringToUint(string memory _privateKey) internal pure returns (uint256) {
        bytes32 hash = keccak256(abi.encodePacked(_privateKey));
        return uint256(hash);
    }
}
