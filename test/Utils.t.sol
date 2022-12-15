// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { toString } from "../src/utils/toString.sol";

contract UtilsTest is PRBTest {
    function testUintToString() public {
        for (uint256 value; value < 10000; value++) {
            assertEq(toString(value), vm.toString(value));
        }
        for (uint256 value; value < 10000; value++) {
            assertEq(toString(10**77 - value), vm.toString(10**77 - value));
            assertEq(toString(10**77 + value), vm.toString(10**77 + value));
        }
        assertEq(toString(type(uint256).max - 1), vm.toString(type(uint256).max - 1));
        assertEq(toString(type(uint256).max), vm.toString(type(uint256).max));
    }

    function testUintToString__Fuzz(uint256 value) public {
        assertEq(toString(value), vm.toString(value));
    }
}