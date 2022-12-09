// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StrSliceAssertions } from "../src/test/StrSliceAssertions.sol";

import { StrSlice, toSlice, StrCharsIter } from "../src/StrSlice.sol";
import { StrChar__InvalidUTF8 } from "../src/StrChar.sol";

using { toSlice } for string;

/// @dev Returns the content of brackets, or empty string if not found
function extractFromBrackets(string memory stuffInBrackets) pure returns (StrSlice extracted) {
    StrSlice s = stuffInBrackets.toSlice();
    bool found;

    (found, , s) = s.splitOnce(toSlice("("));
    if (!found) return toSlice("");

    (found, s, ) = s.rsplitOnce(toSlice(")"));
    if (!found) return toSlice("");

    return s;
}

/// @dev Counts number of disjoint `_pat` in `_haystack` from the start
/// Assumes valid UTF-8
function countOccurrences(string memory _haystack, string memory _pat) pure returns (uint256 counter) {
    uint256 index;
    StrSlice haystack = _haystack.toSlice();
    StrSlice pat = _pat.toSlice();

    while (true) {
        index = haystack.find(pat);
        if (index == type(uint256).max) break;
        haystack = haystack.getSubslice(index + pat.len(), haystack.len());
        counter++;
    }
    return counter;
}

/// @dev Returns a StrSlice of `str` with the 2 first UTF-8 characters removed
/// reverts on invalid UTF8
function removeFirstTwoChars(string memory str) pure returns (StrSlice) {
    StrCharsIter memory chars = str.toSlice().chars();
    for (uint256 i; i < 2; i++) {
        if (chars.isEmpty()) break;
        chars.next();
    }
    return chars.asStr();
}

contract ExamplesTest is PRBTest, StrSliceAssertions {
    function testExtractFromBrackets() public {
        assertEq(
            extractFromBrackets("((1 + 2) + 3) + 4"),
            toSlice("(1 + 2) + 3")
        );
        assertEq(
            extractFromBrackets("((1 + 2) + 3"),
            toSlice("(1 + 2")
        );
        assertEq(
            extractFromBrackets("((1 + 2 + 3"),
            toSlice("")
        );
    }

    function testCountOccurrences() public {
        assertEq(countOccurrences(",", ","), 1);
        assertEq(countOccurrences("1,2,3,456789,10", ","), 4);
        assertEq(countOccurrences("123", ","), 0);
        assertEq(countOccurrences(string(bytes(hex"FF")), "1"), 0);
    }

    function testRemoveFirstTwoChars() public {
        assertEq(removeFirstTwoChars("1"), "");
        assertEq(removeFirstTwoChars("12345"), "345");
        assertEq(removeFirstTwoChars(unicode"こんにちは"), unicode"にちは");
        assertEq(removeFirstTwoChars(unicode"📎!こんにちは"), unicode"こんにちは");
    }

    function testRemoveFirstTwoChars__InvalidUTF8() public {
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        removeFirstTwoChars(string(bytes(hex"FF")));
    }
}