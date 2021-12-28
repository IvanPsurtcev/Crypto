// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract AdvancedMultiTrade {
    function swap(address[] memory tos, bytes[] memory data) external payable {
        require(tos.length > 0 && tos.length == data.length, "Invalid input");

        for (uint256 i; i < tos.length; i++) {
            (bool success, bytes memory returndata) = tos[i].call{value: address(this).balance, gas: gasleft()}(data[i]);
            require(success, string(returndata));
        }
    }

    receive() payable external {}
}
