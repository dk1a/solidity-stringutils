// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { Slice, toSlice } from "../src/Slice.sol";
import { SliceIter } from "../src/SliceIter.sol";
import { SliceIter__StopIteration } from "../src/SliceIter.sol";

using { toSlice } for bytes;

contract SliceIterTest is PRBTest {
    function testLen(bytes calldata _b) public {
        SliceIter memory iter = _b.toSlice().iter();
        assertEq(iter.len(), _b.length);
    }

    function testIsEmpty() public {
        assertTrue(bytes("").toSlice().iter().isEmpty());
        assertFalse(new bytes(1).toSlice().iter().isEmpty());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    NEXT
    //////////////////////////////////////////////////////////////////////////*/

    function testNext() public {
        Slice s = bytes("123").toSlice();
        SliceIter memory iter = s.iter();

        assertEq(iter.next(), uint8(bytes1("1")));
        assertEq(iter.asSlice().toBytes(), bytes("23"));
        assertEq(iter.next(), uint8(bytes1("2")));
        assertEq(iter.asSlice().toBytes(), bytes("3"));
        assertEq(iter.next(), uint8(bytes1("3")));
        assertEq(iter.asSlice().toBytes(), bytes(""));

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }

    function testNext__StopIteration() public {
        Slice s = bytes("123").toSlice();
        SliceIter memory iter = s.iter();

        iter.next();
        iter.next();
        iter.next();

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }

    function testNext__Fuzz(bytes calldata _b) public {
        SliceIter memory iter = _b.toSlice().iter();

        uint256 i;
        while (!iter.isEmpty()) {
            assertEq(iter.next(), uint8(_b[i]));
            assertEq(iter.asSlice().toBytes(), _b[i + 1:]);
            i++;
        }

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }

    function testNext__StopIteration__Fuzz(bytes calldata _b) public {
        SliceIter memory iter = _b.toSlice().iter();

        uint256 i;
        while (!iter.isEmpty()) {
            iter.next();
            i++;
        }

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    NEXT_BACK
    //////////////////////////////////////////////////////////////////////////*/

    function testNextBack() public {
        Slice s = bytes("123").toSlice();
        SliceIter memory iter = s.iter();

        assertEq(iter.nextBack(), uint8(bytes1("3")));
        assertEq(iter.asSlice().toBytes(), bytes("12"));
        assertEq(iter.nextBack(), uint8(bytes1("2")));
        assertEq(iter.asSlice().toBytes(), bytes("1"));
        assertEq(iter.nextBack(), uint8(bytes1("1")));
        assertEq(iter.asSlice().toBytes(), bytes(""));

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.nextBack();
    }

    function testNextBack__StopIteration() public {
        Slice s = bytes("123").toSlice();
        SliceIter memory iter = s.iter();

        iter.nextBack();
        iter.nextBack();
        iter.nextBack();
        
        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.nextBack();
    }

    function testNextBack__Fuzz(bytes calldata _b) public {
        SliceIter memory iter = _b.toSlice().iter();

        uint256 i;
        while (!iter.isEmpty()) {
            assertEq(iter.nextBack(), uint8(_b[_b.length - i - 1]));
            assertEq(iter.asSlice().toBytes(), _b[:_b.length - i - 1]);
            i++;
        }
    }

    function testNextBack__StopIteration__Fuzz(bytes calldata _b) public {
        SliceIter memory iter = _b.toSlice().iter();

        uint256 i;
        while (!iter.isEmpty()) {
            iter.nextBack();
            i++;
        }

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.nextBack();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    NEXT MIXED
    //////////////////////////////////////////////////////////////////////////*/

    function testNextMixed() public {
        Slice s = bytes("12345").toSlice();
        SliceIter memory iter = s.iter();

        assertEq(iter.next(), uint8(bytes1("1")));
        assertEq(iter.asSlice().toBytes(), bytes("2345"));
        assertEq(iter.nextBack(), uint8(bytes1("5")));
        assertEq(iter.asSlice().toBytes(), bytes("234"));
        assertEq(iter.next(), uint8(bytes1("2")));
        assertEq(iter.asSlice().toBytes(), bytes("34"));
        assertEq(iter.next(), uint8(bytes1("3")));
        assertEq(iter.asSlice().toBytes(), bytes("4"));
        assertEq(iter.nextBack(), uint8(bytes1("4")));
        assertEq(iter.asSlice().toBytes(), bytes(""));
    }

    function testNextMixed__StopIteration() public {
        Slice s = bytes("12345").toSlice();
        SliceIter memory iter = s.iter();

        iter.next();
        iter.nextBack();
        iter.next();
        iter.next();
        iter.nextBack();
        
        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }
}