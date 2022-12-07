// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { StrSliceAssertions } from "../src/test/StrSliceAssertions.sol";

import { StrSlice, toSlice, StrSlice__InvalidCharBoundary } from "../src/StrSlice.sol";

using { toSlice } for string;

contract StrSliceTest is PRBTest, StrSliceAssertions {
    function testToString() public {
        string memory _s = unicode"Hello, world!";
        assertEq(_s, _s.toSlice().toString());
    }

    function testLen() public {
        string memory _s = unicode"こんにちは";
        assertEq(bytes(_s).length, _s.toSlice().len());
    }

    function testIsEmpty() public {
        assertTrue(string("").toSlice().isEmpty());
        assertFalse(new string(1).toSlice().isEmpty());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONCATENATION
    //////////////////////////////////////////////////////////////////////////*/

    function testAdd() public {
        assertEq(unicode"こんにちは", toSlice(unicode"こん").add(toSlice(unicode"にちは")));
    }

    function testJoin() public {
        StrSlice[] memory sliceArr = new StrSlice[](3);
        sliceArr[0] = toSlice("Hello");
        sliceArr[1] = toSlice(unicode"こんにちは");
        sliceArr[2] = toSlice("");
        assertEq(
            toSlice(unicode"📎!").join(sliceArr),
            unicode"Hello📎!こんにちは📎!"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    INDEX
    //////////////////////////////////////////////////////////////////////////*/

    function testIsCharBoundary() public {
        string memory _s = unicode"こ";
        // start
        assertTrue(toSlice(_s).isCharBoundary(0));
        // mid
        assertFalse(toSlice(_s).isCharBoundary(1));
        assertFalse(toSlice(_s).isCharBoundary(2));
        // end (isn't a valid index, but is a valid boundary)
        assertTrue(toSlice(_s).isCharBoundary(3));
        // out of bounds
        assertFalse(toSlice(_s).isCharBoundary(4));
    }

    function testGet() public {
        string memory _s = unicode"こんにちは";
        assertEq(_s.toSlice().get(3).toString(), unicode"ん");
    }

    function testGet__InvalidCharBoundary() public {
        string memory _s = unicode"こんにちは";
        vm.expectRevert(StrSlice__InvalidCharBoundary.selector);
        _s.toSlice().get(1);
    }

    function testSplitAt() public {
        string memory _s = unicode"こんにちは";
        (StrSlice s1, StrSlice s2) = _s.toSlice().splitAt(3);
        assertEq(s1.toString(), unicode"こ");
        assertEq(s2.toString(), unicode"んにちは");
    }

    function testSplitAt__InvalidCharBoundary() public {
        string memory _s = unicode"こんにちは";
        vm.expectRevert(StrSlice__InvalidCharBoundary.selector);
        _s.toSlice().splitAt(1);
    }

    function testGetSubslice() public {
        string memory _s = unicode"こんにちは";
        assertEq(_s.toSlice().getSubslice(3, 9).toString(), unicode"んに");
    }

    function testGetSubslice__InvalidCharBoundary() public {
        string memory _s = unicode"こんにちは";
        vm.expectRevert(StrSlice__InvalidCharBoundary.selector);
        _s.toSlice().getSubslice(3, 8);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    SEARCH
    //////////////////////////////////////////////////////////////////////////*/

    function testFind() public {
        string memory s1 = unicode"012こんにちはこんにちは34";
        string memory s2 = unicode"んに";
        uint256 index = s1.toSlice().find(s2.toSlice());
        assertEq(index, 6);
        (, StrSlice rSlice) = s1.toSlice().splitAt(index);
        assertEq(rSlice, unicode"んにちはこんにちは34");
    }

    function testRfind() public {
        string memory s1 = unicode"012こんにちはこんにちは34";
        string memory s2 = unicode"んに";
        uint256 index = s1.toSlice().rfind(s2.toSlice());
        assertEq(index, 21);
        (, StrSlice rSlice) = s1.toSlice().splitAt(index);
        assertEq(rSlice, unicode"んにちは34");
    }

    function testContains() public {
        string memory s1 = unicode"「lorem ipsum」の典型的なテキストのほかにも、原典からの距離の様々なバリエーションが存在する。他のバージョンでは、ラテン語にはあまり登場しないか存在しない";
        string memory s2 = unicode"登場";
        assertTrue(s1.toSlice().contains(s2.toSlice()));
    }

    function testNotContains() public {
        string memory s1 = unicode"「lorem ipsum」の典型的なテキストのほかにも、原典からの距離の様々なバリエーションが存在する。他のバージョンでは、ラテン語にはあまり登場しないか存在しない";
        string memory s2 = unicode"0";
        assertFalse(s1.toSlice().contains(s2.toSlice()));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFY
    //////////////////////////////////////////////////////////////////////////*/

    function testStripPrefix() public {
        StrSlice slice = string(unicode"こんにちは").toSlice();
        assertEq(slice.stripPrefix(string(unicode"こん").toSlice()), string(unicode"にちは"));
        assertEq(slice.stripPrefix(slice),                           "");
        assertEq(slice.stripPrefix(string("").toSlice()),            slice);
        assertEq(slice.stripPrefix(string(unicode"は").toSlice()),   slice);
        assertEq(slice.stripPrefix(string(unicode"こんにちはは").toSlice()), slice);
    }

    function testStripPrefix__FromEmpty() public {
        StrSlice slice = string("").toSlice();
        assertEq(slice.stripPrefix(string(unicode"こ").toSlice()), slice);
        assertEq(slice.stripPrefix(string("").toSlice()),          slice);
    }

    function testStripSuffix() public {
        StrSlice slice = string(unicode"こんにちは").toSlice();
        assertEq(slice.stripSuffix(string(unicode"ちは").toSlice()), string(unicode"こんに"));
        assertEq(slice.stripSuffix(slice),                           "");
        assertEq(slice.stripSuffix(string("").toSlice()),            slice);
        assertEq(slice.stripSuffix(string(unicode"こ").toSlice()),   slice);
        assertEq(slice.stripSuffix(string(unicode"ここんにちは").toSlice()), slice);
    }

    function testStripSuffix__FromEmpty() public {
        StrSlice slice = string("").toSlice();
        assertEq(slice.stripSuffix(string(unicode"こ").toSlice()), slice);
        assertEq(slice.stripSuffix(string("").toSlice()),          slice);
    }

    function testSplitOnce() public {
        StrSlice slice = string(unicode"こんにちはこんにちは").toSlice();
        StrSlice pat = string(unicode"に").toSlice();
        (bool found, StrSlice prefix, StrSlice suffix) = slice.splitOnce(pat);
        assertTrue(found);
        assertEq(prefix, unicode"こん");
        assertEq(suffix, unicode"ちはこんにちは");
    }

    function testSplitOnce__NotFound() public {
        StrSlice slice = string(unicode"こんにちはこんにちは").toSlice();
        StrSlice pat = string(unicode"こに").toSlice();
        (bool found, StrSlice prefix, StrSlice suffix) = slice.splitOnce(pat);
        assertFalse(found);
        assertEq(prefix, unicode"こんにちはこんにちは");
        assertEq(suffix, unicode"");
    }

    function testRsplitOnce() public {
        StrSlice slice = string(unicode"こんにちはこんにちは").toSlice();
        StrSlice pat = string(unicode"に").toSlice();
        (bool found, StrSlice prefix, StrSlice suffix) = slice.rsplitOnce(pat);
        assertTrue(found);
        assertEq(prefix, unicode"こんにちはこん");
        assertEq(suffix, unicode"ちは");
    }

    function testRsplitOnce__NotFound() public {
        StrSlice slice = string(unicode"こんにちはこんにちは").toSlice();
        StrSlice pat = string(unicode"こに").toSlice();
        (bool found, StrSlice prefix, StrSlice suffix) = slice.rsplitOnce(pat);
        assertFalse(found);
        assertEq(prefix, unicode"");
        assertEq(suffix, unicode"こんにちはこんにちは");
    }

    // TODO more tests
}