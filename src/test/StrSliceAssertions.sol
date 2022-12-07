// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { StrSlice, toSlice } from "../StrSlice.sol";

using { toSlice } for string;

/// @title Extension to PRBTest with StrSlice assertions.
/// @dev Also provides lt,lte,gt,gte,contains for 2 native `string`.
contract StrSliceAssertions is PRBTest {
    // Eq

    function assertEq(StrSlice a, StrSlice b) internal {
        assertEq(a.toString(), b.toString());
    }

    function assertEq(StrSlice a, StrSlice b, string memory err) internal {
        assertEq(a.toString(), b.toString(), err);
    }

    function assertEq(StrSlice a, string memory b) internal {
        assertEq(a.toString(), b);
    }

    function assertEq(StrSlice a, string memory b, string memory err) internal {
        assertEq(a.toString(), b, err);
    }

    function assertEq(string memory a, StrSlice b) internal {
        assertEq(a, b.toString());
    }

    function assertEq(string memory a, StrSlice b, string memory err) internal {
        assertEq(a, b.toString(), err);
    }

    // NotEq

    function assertNotEq(StrSlice a, StrSlice b) internal {
        assertNotEq(a.toString(), b.toString());
    }

    function assertNotEq(StrSlice a, StrSlice b, string memory err) internal {
        assertNotEq(a.toString(), b.toString(), err);
    }

    function assertNotEq(StrSlice a, string memory b) internal {
        assertNotEq(a.toString(), b);
    }

    function assertNotEq(StrSlice a, string memory b, string memory err) internal {
        assertNotEq(a.toString(), b, err);
    }

    function assertNotEq(string memory a, StrSlice b) internal {
        assertNotEq(a, b.toString());
    }

    function assertNotEq(string memory a, StrSlice b, string memory err) internal {
        assertNotEq(a, b.toString(), err);
    }

    // Lt

    function assertLt(StrSlice a, StrSlice b) internal virtual {
        if (!a.lt(b)) {
            emit Log("Error: a < b not satisfied [string]");
            emit LogNamedString("  Value a", a.toString());
            emit LogNamedString("  Value b", a.toString());
            fail();
        }
    }

    function assertLt(StrSlice a, StrSlice b, string memory err) internal virtual {
        if (!a.lt(b)) {
            emit LogNamedString("Error", err);
            assertLt(a, b);
        }
    }

    function assertLt(StrSlice a, string memory b) internal virtual {
        assertLt(a, b.toSlice());
    }

    function assertLt(StrSlice a, string memory b, string memory err) internal virtual {
        assertLt(a, b.toSlice(), err);
    }

    function assertLt(string memory a, StrSlice b) internal virtual {
        assertLt(a.toSlice(), b);
    }

    function assertLt(string memory a, StrSlice b, string memory err) internal virtual {
        assertLt(a.toSlice(), b, err);
    }

    function assertLt(string memory a, string memory b) internal virtual {
        assertLt(a.toSlice(), b.toSlice());
    }

    function assertLt(string memory a, string memory b, string memory err) internal virtual {
        assertLt(a.toSlice(), b.toSlice(), err);
    }

    // Lte

    function assertLte(StrSlice a, StrSlice b) internal virtual {
        if (!a.lte(b)) {
            emit Log("Error: a <= b not satisfied [string]");
            emit LogNamedString("  Value a", a.toString());
            emit LogNamedString("  Value b", a.toString());
            fail();
        }
    }

    function assertLte(StrSlice a, StrSlice b, string memory err) internal virtual {
        if (!a.lte(b)) {
            emit LogNamedString("Error", err);
            assertLte(a, b);
        }
    }

    function assertLte(StrSlice a, string memory b) internal virtual {
        assertLte(a, b.toSlice());
    }

    function assertLte(StrSlice a, string memory b, string memory err) internal virtual {
        assertLte(a, b.toSlice(), err);
    }

    function assertLte(string memory a, StrSlice b) internal virtual {
        assertLte(a.toSlice(), b);
    }

    function assertLte(string memory a, StrSlice b, string memory err) internal virtual {
        assertLte(a.toSlice(), b, err);
    }

    function assertLte(string memory a, string memory b) internal virtual {
        assertLte(a.toSlice(), b.toSlice());
    }

    function assertLte(string memory a, string memory b, string memory err) internal virtual {
        assertLte(a.toSlice(), b.toSlice(), err);
    }

    // Gt

    function assertGt(StrSlice a, StrSlice b) internal virtual {
        if (!a.gt(b)) {
            emit Log("Error: a > b not satisfied [string]");
            emit LogNamedString("  Value a", a.toString());
            emit LogNamedString("  Value b", a.toString());
            fail();
        }
    }

    function assertGt(StrSlice a, StrSlice b, string memory err) internal virtual {
        if (!a.gt(b)) {
            emit LogNamedString("Error", err);
            assertGt(a, b);
        }
    }

    function assertGt(StrSlice a, string memory b) internal virtual {
        assertGt(a, b.toSlice());
    }

    function assertGt(StrSlice a, string memory b, string memory err) internal virtual {
        assertGt(a, b.toSlice(), err);
    }

    function assertGt(string memory a, StrSlice b) internal virtual {
        assertGt(a.toSlice(), b);
    }

    function assertGt(string memory a, StrSlice b, string memory err) internal virtual {
        assertGt(a.toSlice(), b, err);
    }

    function assertGt(string memory a, string memory b) internal virtual {
        assertGt(a.toSlice(), b.toSlice());
    }

    function assertGt(string memory a, string memory b, string memory err) internal virtual {
        assertGt(a.toSlice(), b.toSlice(), err);
    }

    // Gte

    function assertGte(StrSlice a, StrSlice b) internal virtual {
        if (!a.gte(b)) {
            emit Log("Error: a >= b not satisfied [string]");
            emit LogNamedString("  Value a", a.toString());
            emit LogNamedString("  Value b", a.toString());
            fail();
        }
    }

    function assertGte(StrSlice a, StrSlice b, string memory err) internal virtual {
        if (!a.gte(b)) {
            emit LogNamedString("Error", err);
            assertGte(a, b);
        }
    }

    function assertGte(StrSlice a, string memory b) internal virtual {
        assertGte(a, b.toSlice());
    }

    function assertGte(StrSlice a, string memory b, string memory err) internal virtual {
        assertGte(a, b.toSlice(), err);
    }

    function assertGte(string memory a, StrSlice b) internal virtual {
        assertGte(a.toSlice(), b);
    }

    function assertGte(string memory a, StrSlice b, string memory err) internal virtual {
        assertGte(a.toSlice(), b, err);
    }

    function assertGte(string memory a, string memory b) internal virtual {
        assertGte(a.toSlice(), b.toSlice());
    }

    function assertGte(string memory a, string memory b, string memory err) internal virtual {
        assertGte(a.toSlice(), b.toSlice(), err);
    }

    // Contains

    function assertContains(StrSlice a, StrSlice b) internal virtual {
        if (!a.contains(b)) {
            emit Log("Error: a does not contain b [string]");
            emit LogNamedString("  String a", a.toString());
            emit LogNamedString("  String b", b.toString());
            fail();
        }
    }

    function assertContains(StrSlice a, StrSlice b, string memory err) internal virtual {
        if (!a.contains(b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }

    function assertContains(StrSlice a, string memory b) internal virtual {
        assertContains(a, b.toSlice());
    }

    function assertContains(StrSlice a, string memory b, string memory err) internal virtual {
        assertContains(a, b.toSlice(), err);
    }

    function assertContains(string memory a, StrSlice b) internal virtual {
        assertContains(a.toSlice(), b);
    }

    function assertContains(string memory a, StrSlice b, string memory err) internal virtual {
        assertContains(a.toSlice(), b, err);
    }

    function assertContains(string memory a, string memory b) internal virtual {
        assertContains(a.toSlice(), b.toSlice());
    }

    function assertContains(string memory a, string memory b, string memory err) internal virtual {
        assertContains(a.toSlice(), b.toSlice(), err);
    }
}