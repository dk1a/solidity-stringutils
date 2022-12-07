// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { Slice, toSlice } from "../Slice.sol";

using { toSlice } for bytes;

/// @title Extension to PRBTest with Slice assertions.
/// @dev Also provides lt,lte,gt,gte,contains for 2 native `bytes`.
contract SliceAssertions is PRBTest {
    // Eq

    function assertEq(Slice a, Slice b) internal {
        assertEq(a.toBytes(), b.toBytes());
    }

    function assertEq(Slice a, Slice b, string memory err) internal {
        assertEq(a.toBytes(), b.toBytes(), err);
    }

    function assertEq(Slice a, bytes memory b) internal {
        assertEq(a.toBytes(), b);
    }

    function assertEq(Slice a, bytes memory b, string memory err) internal {
        assertEq(a.toBytes(), b, err);
    }

    function assertEq(bytes memory a, Slice b) internal {
        assertEq(a, b.toBytes());
    }

    function assertEq(bytes memory a, Slice b, string memory err) internal {
        assertEq(a, b.toBytes(), err);
    }

    // NotEq

    function assertNotEq(Slice a, Slice b) internal {
        assertNotEq(a.toBytes(), b.toBytes());
    }

    function assertNotEq(Slice a, Slice b, string memory err) internal {
        assertNotEq(a.toBytes(), b.toBytes(), err);
    }

    function assertNotEq(Slice a, bytes memory b) internal {
        assertNotEq(a.toBytes(), b);
    }

    function assertNotEq(Slice a, bytes memory b, string memory err) internal {
        assertNotEq(a.toBytes(), b, err);
    }

    function assertNotEq(bytes memory a, Slice b) internal {
        assertNotEq(a, b.toBytes());
    }

    function assertNotEq(bytes memory a, Slice b, string memory err) internal {
        assertNotEq(a, b.toBytes(), err);
    }

    // Lt

    function assertLt(Slice a, Slice b) internal virtual {
        if (!a.lt(b)) {
            emit Log("Error: a < b not satisfied [bytes]");
            emit LogNamedBytes("  Value a", a.toBytes());
            emit LogNamedBytes("  Value b", a.toBytes());
            fail();
        }
    }

    function assertLt(Slice a, Slice b, string memory err) internal virtual {
        if (!a.lt(b)) {
            emit LogNamedString("Error", err);
            assertLt(a, b);
        }
    }

    function assertLt(Slice a, bytes memory b) internal virtual {
        assertLt(a, b.toSlice());
    }

    function assertLt(Slice a, bytes memory b, string memory err) internal virtual {
        assertLt(a, b.toSlice(), err);
    }

    function assertLt(bytes memory a, Slice b) internal virtual {
        assertLt(a.toSlice(), b);
    }

    function assertLt(bytes memory a, Slice b, string memory err) internal virtual {
        assertLt(a.toSlice(), b, err);
    }

    function assertLt(bytes memory a, bytes memory b) internal virtual {
        assertLt(a.toSlice(), b.toSlice());
    }

    function assertLt(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertLt(a.toSlice(), b.toSlice(), err);
    }

    // Lte

    function assertLte(Slice a, Slice b) internal virtual {
        if (!a.lte(b)) {
            emit Log("Error: a <= b not satisfied [bytes]");
            emit LogNamedBytes("  Value a", a.toBytes());
            emit LogNamedBytes("  Value b", a.toBytes());
            fail();
        }
    }

    function assertLte(Slice a, Slice b, string memory err) internal virtual {
        if (!a.lte(b)) {
            emit LogNamedString("Error", err);
            assertLte(a, b);
        }
    }

    function assertLte(Slice a, bytes memory b) internal virtual {
        assertLte(a, b.toSlice());
    }

    function assertLte(Slice a, bytes memory b, string memory err) internal virtual {
        assertLte(a, b.toSlice(), err);
    }

    function assertLte(bytes memory a, Slice b) internal virtual {
        assertLte(a.toSlice(), b);
    }

    function assertLte(bytes memory a, Slice b, string memory err) internal virtual {
        assertLte(a.toSlice(), b, err);
    }

    function assertLte(bytes memory a, bytes memory b) internal virtual {
        assertLte(a.toSlice(), b.toSlice());
    }

    function assertLte(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertLte(a.toSlice(), b.toSlice(), err);
    }

    // Gt

    function assertGt(Slice a, Slice b) internal virtual {
        if (!a.gt(b)) {
            emit Log("Error: a > b not satisfied [bytes]");
            emit LogNamedBytes("  Value a", a.toBytes());
            emit LogNamedBytes("  Value b", a.toBytes());
            fail();
        }
    }

    function assertGt(Slice a, Slice b, string memory err) internal virtual {
        if (!a.gt(b)) {
            emit LogNamedString("Error", err);
            assertGt(a, b);
        }
    }

    function assertGt(Slice a, bytes memory b) internal virtual {
        assertGt(a, b.toSlice());
    }

    function assertGt(Slice a, bytes memory b, string memory err) internal virtual {
        assertGt(a, b.toSlice(), err);
    }

    function assertGt(bytes memory a, Slice b) internal virtual {
        assertGt(a.toSlice(), b);
    }

    function assertGt(bytes memory a, Slice b, string memory err) internal virtual {
        assertGt(a.toSlice(), b, err);
    }

    function assertGt(bytes memory a, bytes memory b) internal virtual {
        assertGt(a.toSlice(), b.toSlice());
    }

    function assertGt(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertGt(a.toSlice(), b.toSlice(), err);
    }

    // Gte

    function assertGte(Slice a, Slice b) internal virtual {
        if (!a.gte(b)) {
            emit Log("Error: a >= b not satisfied [bytes]");
            emit LogNamedBytes("  Value a", a.toBytes());
            emit LogNamedBytes("  Value b", a.toBytes());
            fail();
        }
    }

    function assertGte(Slice a, Slice b, string memory err) internal virtual {
        if (!a.gte(b)) {
            emit LogNamedString("Error", err);
            assertGte(a, b);
        }
    }

    function assertGte(Slice a, bytes memory b) internal virtual {
        assertGte(a, b.toSlice());
    }

    function assertGte(Slice a, bytes memory b, string memory err) internal virtual {
        assertGte(a, b.toSlice(), err);
    }

    function assertGte(bytes memory a, Slice b) internal virtual {
        assertGte(a.toSlice(), b);
    }

    function assertGte(bytes memory a, Slice b, string memory err) internal virtual {
        assertGte(a.toSlice(), b, err);
    }

    function assertGte(bytes memory a, bytes memory b) internal virtual {
        assertGte(a.toSlice(), b.toSlice());
    }

    function assertGte(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertGte(a.toSlice(), b.toSlice(), err);
    }

    // Contains

    function assertContains(Slice a, Slice b) internal virtual {
        if (!a.contains(b)) {
            emit Log("Error: a does not contain b [bytes]");
            emit LogNamedBytes("  Bytes a", a.toBytes());
            emit LogNamedBytes("  Bytes b", b.toBytes());
            fail();
        }
    }

    function assertContains(Slice a, Slice b, string memory err) internal virtual {
        if (!a.contains(b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }

    function assertContains(Slice a, bytes memory b) internal virtual {
        assertContains(a, b.toSlice());
    }

    function assertContains(Slice a, bytes memory b, string memory err) internal virtual {
        assertContains(a, b.toSlice(), err);
    }

    function assertContains(bytes memory a, Slice b) internal virtual {
        assertContains(a.toSlice(), b);
    }

    function assertContains(bytes memory a, Slice b, string memory err) internal virtual {
        assertContains(a.toSlice(), b, err);
    }

    function assertContains(bytes memory a, bytes memory b) internal virtual {
        assertContains(a.toSlice(), b.toSlice());
    }

    function assertContains(bytes memory a, bytes memory b, string memory err) internal virtual {
        assertContains(a.toSlice(), b.toSlice(), err);
    }
}