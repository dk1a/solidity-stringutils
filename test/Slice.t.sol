// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { SliceAssertions } from "../src/test/SliceAssertions.sol";

import { Slice, Slice__, toSlice } from "../src/Slice.sol";
import { Slice__OutOfBounds } from "../src/Slice.sol";

using { toSlice } for bytes;

contract SliceTest is PRBTest, SliceAssertions {
    function checkOffset(bytes memory b1, bytes memory b2, uint256 offset) internal {
        require(b2.length <= b1.length, "checkOffset expects b2.length <= b1.length");
        for (uint256 i; i < b2.length; i++) {
            assertEq(b1[offset + i], b2[i]);
        }
    }

    function testLen(bytes calldata _b) public {
        assertEq(_b.toSlice().len(), _b.length);
    }

    function testIsEmpty() public {
        assertTrue(bytes("").toSlice().isEmpty());
        assertFalse(new bytes(1).toSlice().isEmpty());
    }

    function testToBytes(bytes calldata _b) public {
        assertEq(_b, _b.toSlice().toBytes());
    }

    function testToBytes32(bytes memory _b) public {
        bytes32 b32;
        if (_b.length > 0) {
            /// @solidity memory-safe-assembly
            assembly {
                b32 := mload(add(_b, 0x20))
            }
        }
        assertEq(b32, _b.toSlice().toBytes32());
    }

    function testKeccak__Eq(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory b2 = _b;
        
        assertEq(b1.toSlice().keccak(), b2.toSlice().keccak());
        assertEq(keccak256(b1), keccak256(b2));
        assertEq(b1.toSlice().keccak(), keccak256(b1));
    }

    function testKeccak__NotEq(bytes calldata _b) public {
        vm.assume(_b.length > 0);
        bytes memory b1 = _b;
        bytes memory b2 = _b;

        uint256 i = uint256(keccak256(abi.encode(_b, "i"))) % _b.length;
        b1[i] ^= 0x01;
        assertEq(b1.toSlice().keccak(), keccak256(b1));
        assertNotEq(b1.toSlice().keccak(), b2.toSlice().keccak());
        assertNotEq(keccak256(b1), keccak256(b2));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    COMPARE
    //////////////////////////////////////////////////////////////////////////*/

    // don't use slice assertions here, since that'd be testing them with themselves
    function testCmp() public {
        assertGt(toSlice("1").cmp(toSlice("0")),  0);
        assertEq(toSlice("1").cmp(toSlice("1")),  0);
        assertLt(toSlice("0").cmp(toSlice("1")),  0);
        assertGt(toSlice("1").cmp(toSlice("")),   0);
        assertEq(toSlice("").cmp(toSlice("")),    0);
        assertLt(toSlice("").cmp(toSlice("1")),   0);
        assertGt(toSlice("12").cmp(toSlice("1")), 0);
        assertLt(toSlice("1").cmp(toSlice("12")), 0);
    }

    function testCmp__Long() public {
        bytes memory b0  = "1234567890______________________________________________________0";
        bytes memory b1  = "1234567890______________________________________________________1";
        bytes memory b12 = "1234567890______________________________________________________12";
        bytes memory bn  = "1234567890______________________________________________________";

        assertGt(toSlice(b1).cmp(toSlice(b0)),  0);
        assertEq(toSlice(b1).cmp(toSlice(b1)),  0);
        assertLt(toSlice(b0).cmp(toSlice(b1)),  0);
        assertGt(toSlice(b1).cmp(toSlice(bn)),  0);
        assertEq(toSlice(bn).cmp(toSlice(bn)),  0);
        assertLt(toSlice(bn).cmp(toSlice(b1)),  0);
        assertGt(toSlice(b12).cmp(toSlice(b1)), 0);
        assertLt(toSlice(b1).cmp(toSlice(b12)), 0);
    }

    // TODO more comparison tests for specialized funcs

    /*//////////////////////////////////////////////////////////////////////////
                                        COPY
    //////////////////////////////////////////////////////////////////////////*/

    function _copyFromValue(uint256 length, bytes32 value) internal pure returns (Slice slice) {
        bytes memory b = new bytes(length);
        slice = b.toSlice();
        slice.copyFromValue(value, length);
    }

    function _copyFromValueRightAligned(uint256 length, bytes32 value) internal pure returns (Slice slice) {
        bytes memory b = new bytes(length);
        slice = b.toSlice();
        slice.copyFromValueRightAligned(value, length);
    }

    function testCopyFromSlice(bytes calldata _b) public {
        Slice sliceSrc = _b.toSlice();

        bytes memory bDest = new bytes(_b.length);
        Slice sliceDest = bDest.toSlice();
        sliceDest.copyFromSlice(sliceSrc);

        assertEq(sliceDest, sliceSrc);
    }

    function testCopyFromValue__Fuzz(bytes32 value) public {
        bytes memory b = new bytes(32);
        Slice slice = b.toSlice();

        slice.copyFromValue(value, 32);

        assertEq(slice, abi.encodePacked(value));
    }

    function testCopyFromValue__LeftAligned() public {
        bytes1 v1 = "1";
        assertEq(_copyFromValue(1, bytes32(v1)), abi.encodePacked(v1));

        bytes2 v2 = "22";
        assertEq(_copyFromValue(2, bytes32(v2)), abi.encodePacked(v2));

        bytes16 v16 = "1234567890123456";
        assertEq(_copyFromValue(16, bytes32(v16)), abi.encodePacked(v16));

        bytes25 v25 = "1234567890123456789012345";
        assertEq(_copyFromValue(25, bytes32(v25)), abi.encodePacked(v25));

        bytes32 v32 = "12345678901234567890123456789012";
        assertEq(_copyFromValue(32, bytes32(v32)), abi.encodePacked(v32));
    }

    function testCopyFromValue__RightAligned() public {
        uint8 v1 = 1;
        assertEq(_copyFromValueRightAligned(1, bytes32(uint256(v1))), abi.encodePacked(v1));

        uint16 v2 = 1000;
        assertEq(_copyFromValueRightAligned(2, bytes32(uint256(v2))), abi.encodePacked(v2));

        uint128 v16 = 2**15 + 1;
        assertEq(_copyFromValueRightAligned(16, bytes32(uint256(v16))), abi.encodePacked(v16));

        uint200 v25 = 123;
        assertEq(_copyFromValueRightAligned(25, bytes32(uint256(v25))), abi.encodePacked(v25));

        uint256 v32 = type(uint256).max;
        assertEq(_copyFromValueRightAligned(32, bytes32(uint256(v32))), abi.encodePacked(v32));
    }

    function testCopyFromValue__Multiple() public {
        bytes memory b = new bytes(86);
        Slice slice = b.toSlice();

        slice.copyFromValueRightAligned(bytes32(uint256(1)), 1);
        slice = slice.getAfter(1);

        slice.copyFromValueRightAligned(bytes32(uint256(1000)), 2);
        slice = slice.getAfter(2);

        slice.copyFromValue("12345678901", 11);
        slice = slice.getAfter(11);

        slice.copyFromValue("12345678901234567890123456789012", 32);
        slice = slice.getAfter(32);

        // address to bytes20 has an autoshift
        slice.copyFromValue(bytes20(address(this)), 20);
        slice = slice.getAfter(20);

        // try it without autoshift too
        address addr = address(this);
        bytes32 addrRaw;
        assembly {
            addrRaw := addr
        }
        slice.copyFromValueRightAligned(addrRaw, 20);
        slice = slice.getAfter(20);

        assertEq(
            b,
            abi.encodePacked(
                uint8(1),
                uint16(1000),
                bytes11("12345678901"),
                bytes32("12345678901234567890123456789012"),
                bytes20(address(this)),
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONCATENATION
    //////////////////////////////////////////////////////////////////////////*/

    function testAdd(bytes calldata _b) public {
        bytes memory b1 = _b[:_b.length / 2];
        bytes memory b2 = _b[_b.length / 2:];

        assertEq(b1.toSlice().add(b2.toSlice()), _b);
    }

    function testJoin__EmptySeparator(bytes calldata _b) public {
        bytes memory b1 = _b[:_b.length / 2];
        bytes memory b2 = _b[_b.length / 2:];

        bytes memory sep;
        Slice[] memory slices = new Slice[](2);
        slices[0] = b1.toSlice();
        slices[1] = b2.toSlice();

        assertEq(sep.toSlice().join(slices), _b);
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

        assertEq(sep.toSlice().join(slices), abi.encodePacked(b1, sep, b2, sep, b3));
    }

    function testJoin__ArrayLen1(bytes calldata _b) public {
        bytes memory b1 = _b;
        bytes memory sep = hex'ABCD';

        Slice[] memory slices = new Slice[](1);
        slices[0] = b1.toSlice();

        assertEq(sep.toSlice().join(slices), abi.encodePacked(b1));
    }

    function testJoin__ArrayLen0() public {
        bytes memory sep = hex'ABCD';

        Slice[] memory slices;

        assertEq(sep.toSlice().join(slices), '');
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
            abi.encodePacked(
                s1.toBytes(), s2.toBytes()
            ),
            _b
        );
    }

    function testSplitAt__0(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        (Slice s1, Slice s2) = slice.splitAt(0);
        assertEq(s2.toBytes(), _b);
        assertEq(s1.len(), 0);
    }

    function testSplitAt__Length(bytes calldata _b) public {
        Slice slice = _b.toSlice();
        (Slice s1, Slice s2) = slice.splitAt(_b.length);
        assertEq(s1.toBytes(), _b);
        assertEq(s2.len(), 0);
    }

    function testGetSubslice(bytes calldata _b) public {
        // TODO fix self-referential pseudorandomness
        uint256 start = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "start"))) % _b.length;
        uint256 end = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "end"))) % _b.length;
        vm.assume(start <= end);
        Slice subslice = _b.toSlice().getSubslice(start, end);
        assertEq(subslice.toBytes(), _b[start:end]);
    }

    function testGetSubslice__RevertStartAfterEnd(bytes calldata _b) public {
        // TODO fix self-referential pseudorandomness
        uint256 start = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "start"))) % _b.length;
        uint256 end = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "end"))) % _b.length;
        vm.assume(start > end);
        vm.expectRevert(Slice__OutOfBounds.selector);
        _b.toSlice().getSubslice(start, end);
    }

    function testGetBefore(bytes calldata _b) public {
        Slice s1 = _b.toSlice().getBefore(_b.length / 2);
        assertEq(s1, _b[:_b.length / 2]);
    }

    function testGetBefore_RevertOutOfBounds() public {
        bytes memory _b;
        vm.expectRevert(Slice__OutOfBounds.selector);
        _b.toSlice().getBefore(1);
    }

    function testGetAfter(bytes calldata _b) public {
        Slice s1 = _b.toSlice().getAfter(_b.length / 2);
        assertEq(s1, _b[_b.length / 2:]);
    }

    function testGetAfter_RevertOutOfBounds() public {
        bytes memory _b;
        vm.expectRevert(Slice__OutOfBounds.selector);
        _b.toSlice().getAfter(1);
    }

    function testGetAfterStrict(bytes calldata _b) public {
        vm.assume(_b.length > 0);
        Slice s1 = _b.toSlice().getAfterStrict(_b.length / 2);
        assertEq(s1, _b[_b.length / 2:]);
    }

    function testGetAfterStrict_RevertOutOfBounds() public {
        bytes memory _b;
        vm.expectRevert(Slice__OutOfBounds.selector);
        _b.toSlice().getAfterStrict(0);
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

    /*//////////////////////////////////////////////////////////////////////////
                                        SEARCH
    //////////////////////////////////////////////////////////////////////////*/

    function testContains(bytes calldata _b) public {
        vm.assume(_b.length > 0);
        bytes memory pat = _b[_b.length / 2:_b.length / 2 + 1];
        assertTrue(_b.toSlice().contains(pat.toSlice()));
    }

    function testContains__NotFound() public {
        bytes memory _b = "123456789";
        bytes memory pat = "0";
        assertFalse(_b.toSlice().contains(pat.toSlice()));
    }

    function testContains__EmptySelf() public {
        bytes memory _b = "";
        bytes memory pat = "0";
        assertFalse(_b.toSlice().contains(pat.toSlice()));
    }

    function testContains__EmptyPat() public {
        bytes memory _b = "123456789";
        bytes memory pat = "";
        assertTrue(_b.toSlice().contains(pat.toSlice()));
    }

    function testContains__EmptyBoth() public {
        bytes memory _b = "";
        bytes memory pat = "";
        assertTrue(_b.toSlice().contains(pat.toSlice()));
    }

    function testStartsWith(bytes calldata _b) public {
        uint256 i = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "i"))) % _b.length;
        bytes memory pat = _b[:i];
        assertTrue(_b.toSlice().startsWith(pat.toSlice()));
    }

    function testStartsWith__False() public {
        bytes memory _b = "123456789";
        assertFalse(_b.toSlice().startsWith(bytes("2").toSlice()));
        assertFalse(_b.toSlice().startsWith(bytes("9").toSlice()));
    }

    function testEndsWith(bytes calldata _b) public {
        uint256 i = _b.length == 0 ? 0 : uint256(keccak256(abi.encode(_b, "i"))) % _b.length;
        bytes memory pat = _b[i:];
        assertTrue(_b.toSlice().endsWith(pat.toSlice()));
    }

    function testEndsWith__False() public {
        bytes memory _b = "123456789";
        assertFalse(_b.toSlice().endsWith(bytes("1").toSlice()));
        assertFalse(_b.toSlice().endsWith(bytes("8").toSlice()));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        MODIFY
    //////////////////////////////////////////////////////////////////////////*/

    function testStripPrefix() public {
        bytes memory _b = "12345";
        assertEq(_b.toSlice().stripPrefix(bytes("123").toSlice()),    bytes("45"));
        assertEq(_b.toSlice().stripPrefix(_b.toSlice()),              bytes(""));
        assertEq(_b.toSlice().stripPrefix(bytes("").toSlice()),       _b);
        assertEq(_b.toSlice().stripPrefix(bytes("5").toSlice()),      _b);
        assertEq(_b.toSlice().stripPrefix(bytes("123456").toSlice()), _b);
    }

    function testStripPrefix__FromEmpty() public {
        bytes memory _b;
        assertEq(_b.toSlice().stripPrefix(bytes("1").toSlice()), _b);
        assertEq(_b.toSlice().stripPrefix(bytes("").toSlice()),  _b);
    }

    function testStripSuffix() public {
        bytes memory _b = "12345";
        assertEq(_b.toSlice().stripSuffix(bytes("345").toSlice()),    bytes("12"));
        assertEq(_b.toSlice().stripSuffix(_b.toSlice()),              bytes(""));
        assertEq(_b.toSlice().stripSuffix(bytes("").toSlice()),       _b);
        assertEq(_b.toSlice().stripSuffix(bytes("1").toSlice()),      _b);
        assertEq(_b.toSlice().stripSuffix(bytes("123456").toSlice()), _b);
    }

    function testStripSuffix__FromEmpty() public {
        bytes memory _b;
        assertEq(_b.toSlice().stripSuffix(bytes("1").toSlice()), _b);
        assertEq(_b.toSlice().stripSuffix(bytes("").toSlice()),  _b);
    }
}