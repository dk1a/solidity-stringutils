// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { SliceAssertions } from "../src/test/SliceAssertions.sol";

import { Slice, toSlice } from "../src/Slice.sol";

using { toSlice } for bytes;

contract SliceAssertionsTest is PRBTest, SliceAssertions {
    // 100 bytes
    bytes constant LOREM_IPSUM = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore.";

    /// @dev simple byte-by-byte comparison to test more complicated comparisons
    function naiveCmp(bytes memory b1, bytes memory b2) internal pure returns (int256) {
        uint256 shortest = b1.length < b2.length ? b1.length : b2.length;
        for (uint256 i; i < shortest; i++) {
            if (b1[i] < b2[i]) {
                return -1;
            } else if (b1[i] > b2[i]) {
                return 1;
            }
        }
        if (b1.length < b2.length) {
            return -1;
        } else if (b1.length > b2.length) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @dev split calldata bytes in half
    function b1b2(bytes calldata b) internal pure returns (bytes memory b1, bytes memory b2) {
        b1 = b[:b.length / 2];
        // b2 can be 1 byte longer sometimes
        b2 = b[b.length / 2:];

        // this is useful to test a special case of initially similar sequences
        // TODO fix self-referential pseudorandomness
        uint256 random = uint256(keccak256(abi.encode(b, "randomlyAddPrefix"))) % 4;
        if (random == 1) {
            // prefix
            b1 = abi.encodePacked(LOREM_IPSUM, b1);
            b2 = abi.encodePacked(LOREM_IPSUM, b2);
        } else if (random == 2) {
            // suffix
            b1 = abi.encodePacked(b1, LOREM_IPSUM);
            b2 = abi.encodePacked(b2, LOREM_IPSUM);
        } else if (random == 3) {
            // prefix and suffix
            b1 = abi.encodePacked(LOREM_IPSUM, b1, LOREM_IPSUM);
            b2 = abi.encodePacked(LOREM_IPSUM, b2, LOREM_IPSUM);
        }
    }

    function testNaiveCmp() public {
        assertEq(naiveCmp("1", "0"),   1);
        assertEq(naiveCmp("1", "1"),   0);
        assertEq(naiveCmp("0", "1"),  -1);
        assertEq(naiveCmp("1", ""),    1);
        assertEq(naiveCmp("", ""),     0);
        assertEq(naiveCmp("", "1"),   -1);
        assertEq(naiveCmp("12", "1"),  1);
        assertEq(naiveCmp("1", "12"), -1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        EQUALITY
    //////////////////////////////////////////////////////////////////////////*/

    function testEq(bytes memory b) public {
        // compare new assertions
        assertEq(b.toSlice(), b.toSlice());
        assertEq(b.toSlice(), b);
        assertEq(b, b.toSlice());

        assertLte(b.toSlice(), b.toSlice());
        assertLte(b.toSlice(), b);
        assertLte(b, b.toSlice());

        assertGte(b.toSlice(), b.toSlice());
        assertGte(b.toSlice(), b);
        assertGte(b, b.toSlice());
        // to the existing ones
        assertEq(b.toSlice().toBytes(), b.toSlice().toBytes());
        assertEq(b.toSlice().toBytes(), b);
        assertEq(b, b.toSlice().toBytes());
    }

    function testFailEq(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(keccak256(b1) != keccak256(b2));
        assertEq(b1.toSlice(), b2.toSlice());
    }

    function testNotEq(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(keccak256(b1) != keccak256(b2));
        // compare new assertions
        assertNotEq(b1.toSlice(), b2.toSlice());
        assertNotEq(b1.toSlice(), b2);
        assertNotEq(b1, b2.toSlice());
        // to the existing ones
        assertNotEq(b1.toSlice().toBytes(), b2.toSlice().toBytes());
        assertNotEq(b1.toSlice().toBytes(), b2);
        assertNotEq(b1, b2.toSlice().toBytes());
    }

    function testFailNotEq(bytes memory b) public {
        assertNotEq(b.toSlice(), b.toSlice());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    LESS-THAN
    //////////////////////////////////////////////////////////////////////////*/

    function testLt(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(naiveCmp(b1, b2) < 0);

        assertLt(b1.toSlice(), b2.toSlice());
        assertLt(b1.toSlice(), b2);
        assertLt(b1, b2.toSlice());
        assertLt(b1, b2);

        assertLte(b1.toSlice(), b2.toSlice());
        assertLte(b1.toSlice(), b2);
        assertLte(b1, b2.toSlice());
        assertLte(b1, b2);
    }

    function testFailLt(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(naiveCmp(b1, b2) > 0);

        assertLt(b1.toSlice(), b2.toSlice());
    }

    function testFailLt__ForEq(bytes memory b) public {
        assertLt(b.toSlice(), b.toSlice());
    }

    function testFailLte(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(naiveCmp(b1, b2) > 0);

        assertLte(b1.toSlice(), b2.toSlice());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GREATER-THAN
    //////////////////////////////////////////////////////////////////////////*/

    function testGt(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(naiveCmp(b1, b2) > 0);

        assertGt(b1.toSlice(), b2.toSlice());
        assertGt(b1.toSlice(), b2);
        assertGt(b1, b2.toSlice());
        assertGt(b1, b2);

        assertGte(b1.toSlice(), b2.toSlice());
        assertGte(b1.toSlice(), b2);
        assertGte(b1, b2.toSlice());
        assertGte(b1, b2);
    }

    function testFailGt(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(naiveCmp(b1, b2) < 0);

        assertGt(b1.toSlice(), b2.toSlice());
    }

    function testFailGt__ForEq(bytes memory b) public {
        assertGt(b.toSlice(), b.toSlice());
    }

    function testFailGte(bytes calldata _b) public {
        (bytes memory b1, bytes memory b2) = b1b2(_b);
        vm.assume(naiveCmp(b1, b2) < 0);

        assertGte(b1.toSlice(), b2.toSlice());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTAINS
    //////////////////////////////////////////////////////////////////////////*/

    function testContains(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2 = _b[_b.length / 3 : _b.length * 2 / 3];

        assertContains(b1.toSlice(), b2.toSlice());
        assertContains(b1.toSlice(), b2);
        assertContains(b1, b2.toSlice());
        assertContains(b1, b2);
    }

    function testFailContains(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2 = _b;
        // change 1 byte
        b2[0] = bytes1(uint8(b2[0]) ^ uint8(0x01));

        assertContains(b1.toSlice(), b2.toSlice());
    }

    function testFailContains__1Byte(bytes calldata _b) public {
        bytes1 pat = bytes1(keccak256(abi.encode(_b, "1Byte")));

        bytes memory b1 = _b;
        bytes memory b2 = new bytes(1);
        b2[0] = pat;
        // replace all pat
        for (uint256 i; i < b1.length; i++) {
            if (b1[i] == pat) {
                b1[i] = ~pat;
            }
        }

        assertContains(b1.toSlice(), b2.toSlice());
    }
}