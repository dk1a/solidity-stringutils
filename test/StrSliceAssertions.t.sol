// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StrSliceAssertions } from "../src/test/StrSliceAssertions.sol";

import { StrSlice, toSlice } from "../src/StrSlice.sol";

using { toSlice } for string;

// StrSlice just wraps Slice's comparators, so these tests don't fuzz
// TODO currently invalid UTF-8 compares like bytes, but should it revert?
contract StrSliceAssertionsTest is PRBTest, StrSliceAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                        EQUALITY
    //////////////////////////////////////////////////////////////////////////*/

    function testEq() public {
        string memory b = unicode"こんにちは";
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
        assertEq(b.toSlice().toString(), b.toSlice().toString());
        assertEq(b.toSlice().toString(), b);
        assertEq(b, b.toSlice().toString());
    }

    function testFailEq() public {
        assertEq(string(unicode"こん"), string(unicode"こ"));
    }

    function testNotEq() public {
        string memory b1 = unicode"こ";
        string memory b2 = unicode"ん";
        // compare new assertions
        assertNotEq(b1.toSlice(), b2.toSlice());
        assertNotEq(b1.toSlice(), b2);
        assertNotEq(b1, b2.toSlice());
        // to the existing ones
        assertNotEq(b1.toSlice().toString(), b2.toSlice().toString());
        assertNotEq(b1.toSlice().toString(), b2);
        assertNotEq(b1, b2.toSlice().toString());
    }

    function testFailNotEq() public {
        assertNotEq(string(unicode"こんにちは"), string(unicode"こんにちは"));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    LESS-THAN
    //////////////////////////////////////////////////////////////////////////*/

    function testLt() public {
        string memory b1 = unicode"こ";
        string memory b2 = unicode"ん";

        assertLt(b1.toSlice(), b2.toSlice());
        assertLt(b1.toSlice(), b2);
        assertLt(b1, b2.toSlice());
        assertLt(b1, b2);

        assertLte(b1.toSlice(), b2.toSlice());
        assertLte(b1.toSlice(), b2);
        assertLte(b1, b2.toSlice());
        assertLte(b1, b2);
    }

    function testFailLt() public {
        string memory b1 = unicode"こ";
        string memory b2 = unicode"ん";

        assertLt(b2, b1);
    }

    function testFailLt__ForEq() public {
        string memory b = unicode"こ";
        assertLt(b, b);
    }

    function testFailLte() public {
        string memory b1 = unicode"こ";
        string memory b2 = unicode"ん";

        assertLte(b2, b1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GREATER-THAN
    //////////////////////////////////////////////////////////////////////////*/

    function testGt() public {
        string memory b1 = unicode"ん";
        string memory b2 = unicode"こ";

        assertGt(b1.toSlice(), b2.toSlice());
        assertGt(b1.toSlice(), b2);
        assertGt(b1, b2.toSlice());
        assertGt(b1, b2);

        assertGte(b1.toSlice(), b2.toSlice());
        assertGte(b1.toSlice(), b2);
        assertGte(b1, b2.toSlice());
        assertGte(b1, b2);
    }

    function testFailGt() public {
        string memory b1 = unicode"ん";
        string memory b2 = unicode"こ";

        assertGt(b2, b1);
    }

    function testFailGt__ForEq() public {
        string memory b = unicode"こ";
        assertGt(b, b);
    }

    function testFailGte() public {
        string memory b1 = unicode"ん";
        string memory b2 = unicode"こ";

        assertGte(b2, b1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONTAINS
    //////////////////////////////////////////////////////////////////////////*/

    function testContains() public {
        string memory b1 = unicode"こんにちは";
        string memory b2 = unicode"んにち";

        assertContains(b1.toSlice(), b2.toSlice());
        assertContains(b1.toSlice(), b2);
        assertContains(b1, b2.toSlice());
        assertContains(b1, b2);
    }

    function testFailContains() public {
        string memory b1 = unicode"こんにちは";
        string memory b2 = unicode"ここ";

        assertContains(b1, b2);
    }
}