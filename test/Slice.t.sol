// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Assertions } from "../src/test/Assertions.sol";

import { Slice, Slice__, toSlice } from "../src/Slice.sol";
import { Slice__OutOfBounds } from "../src/Slice.sol";

using { toSlice } for bytes;

contract SliceTest is PRBTest, Assertions {
    function checkOffset(bytes memory b1, bytes memory b2, uint256 offset) internal {
        require(b2.length <= b1.length, "checkOffset expects b2.length <= b1.length");
        for (uint256 i; i < b2.length; i++) {
            assertEq(b1[offset + i], b2[i]);
        }
    }

    // skipping cmp tests, that's covered by SliceAssertionsTest
    // TODO explicitly test stuff like copyFromSlice,startsWith etc
    // (tho it's likely fine due to other tests)

    function testLen(bytes calldata _b) public {
        assertEq(_b.toSlice().len(), _b.length);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONCATENATION
    //////////////////////////////////////////////////////////////////////////*/

    function testAdd(bytes calldata _b) public {
        bytes memory b1 = _b[:_b.length / 2];
        bytes memory b2 = _b[_b.length / 2:];

        assertEq(
            keccak256(b1.toSlice().add(b2.toSlice())),
            keccak256(_b)
        );
    }

    function testJoin__EmptySeparator(bytes calldata _b) public {
        bytes memory b1 = _b[:_b.length / 2];
        bytes memory b2 = _b[_b.length / 2:];

        bytes memory sep;
        Slice[] memory slices = new Slice[](2);
        slices[0] = b1.toSlice();
        slices[1] = b2.toSlice();

        assertEq(
            keccak256(sep.toSlice().join(slices)),
            keccak256(_b)
        );
    }

    function testJoin__RandomSeparator(bytes calldata _b) public {
        bytes memory b1 = _b[:_b.length * 1/4];
        bytes memory b2 = _b[_b.length * 1/4:_b.length * 2/4];
        bytes memory b3 = _b[_b.length * 2/4:_b.length * 3/4];
        bytes memory sep = _b[_b.length * 3/4:];

        Slice[] memory slices = new Slice[](3);
        slices[0] = b1.toSlice();
        slices[1] = b2.toSlice();
        slices[2] = b3.toSlice();

        assertEq(
            keccak256(sep.toSlice().join(slices)),
            keccak256(abi.encodePacked(b1, sep, b2, sep, b3))
        );
    }

    function testJoin__ArrayLen1(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory sep = hex'ABCD';

        Slice[] memory slices = new Slice[](1);
        slices[0] = b1.toSlice();

        assertEq(
            keccak256(sep.toSlice().join(slices)),
            keccak256(abi.encodePacked(b1))
        );
    }

    function testJoin__ArrayLen0() public {
        bytes memory sep = hex'ABCD';

        Slice[] memory slices;

        assertEq(
            keccak256(sep.toSlice().join(slices)),
            keccak256('')
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        INDEX
    //////////////////////////////////////////////////////////////////////////*/

    function testGet(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        for (uint256 i; i < _b.length; i++) {
            assertEq(slice.get(i), uint8(_b[i]));
        }
    }

    function testGet__RevertOutOfBounds(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        vm.expectRevert(Slice__OutOfBounds.selector);
        slice.get(_b.length);
    }

    function testFirstLast(bytes calldata _b) public {
        vm.assume(_b.length > 0);
        Slice slice = _b.toSlice();
        assertEq(slice.first(), uint8(_b[0]));
        assertEq(slice.last(), uint8(_b[_b.length - 1]));
    }

    function testSplitAt(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        (Slice s1, Slice s2) = slice.splitAt(_b.length / 2);
        assertEq(
            keccak256(abi.encodePacked(
                s1.copyToBytes(), s2.copyToBytes()
            )),
            keccak256(_b)
        );
    }

    function testSplitAt__0(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        (Slice s1, Slice s2) = slice.splitAt(0);
        assertEq(
            keccak256(s2.copyToBytes()),
            keccak256(_b)
        );
        assertEq(s1.len(), 0);
    }

    function testSplitAt__Length(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        (Slice s1, Slice s2) = slice.splitAt(_b.length);
        assertEq(
            keccak256(s1.copyToBytes()),
            keccak256(_b)
        );
        assertEq(s2.len(), 0);
    }

    function testGetSubslice(bytes calldata _b) public {
        // TODO fix self-referential pseudorandomness
        uint256 start = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "start"))) % _b.length;
        uint256 end = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "end"))) % _b.length;
        vm.assume(start <= end);
        Slice subslice = _b.toSlice().getSubslice(start, end);
        assertEq(
            keccak256(subslice.copyToBytes()),
            keccak256(_b[start:end])
        );
    }

    function testGetSubslice__RevertStartAfterEnd(bytes calldata _b) public {
        // TODO fix self-referential pseudorandomness
        uint256 start = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "start"))) % _b.length;
        uint256 end = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "end"))) % _b.length;
        vm.assume(start > end);
        vm.expectRevert(Slice__OutOfBounds.selector);
        _b.toSlice().getSubslice(start, end);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        FIND
    //////////////////////////////////////////////////////////////////////////*/

	function testFind(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2 = _b[_b.length / 8 : _b.length * 3 / 8];
        vm.assume(b2.length > 0);

        uint256 offset = b1.toSlice().find(b2.toSlice());
        // don't use assertContains here, since that'd be testing find with find itself
        checkOffset(b1, b2, offset);
    }

    function testFindEmpty(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2;

        uint256 offset = b1.toSlice().find(b2.toSlice());
        assertEq(offset, 0);
    }

    function testFindEmptyInEmpty() public {
        bytes memory b1;
        bytes memory b2;

        uint256 offset = b1.toSlice().find(b2.toSlice());
        assertEq(offset, 0);
    }

    function testFindNotEmptyInEmpty(bytes calldata _b) public {
        vm.assume(_b.length > 0);
        bytes memory b1;
        bytes memory b2 = _b;

        uint256 offset = b1.toSlice().find(b2.toSlice());
        assertEq(offset, type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        RFIND
    //////////////////////////////////////////////////////////////////////////*/

    function testRfind(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2 = _b[_b.length * 5 / 8 : _b.length * 7 / 8];
        vm.assume(b2.length > 0);

        uint256 offset = b1.toSlice().rfind(b2.toSlice());
        checkOffset(b1, b2, offset);
    }

    function testRfindEmpty(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2;

        uint256 offset = b1.toSlice().rfind(b2.toSlice());
        assertEq(offset, 0);
    }

    function testRfindEmptyInEmpty() public {
        bytes memory b1;
        bytes memory b2;

        uint256 offset = b1.toSlice().rfind(b2.toSlice());
        assertEq(offset, 0);
    }

    function testRfindNotEmptyInEmpty(bytes calldata _b) public {
        vm.assume(_b.length > 0);
        bytes memory b1;
        bytes memory b2 = _b;

        uint256 offset = b1.toSlice().rfind(b2.toSlice());
        assertEq(offset, type(uint256).max);
    }
}