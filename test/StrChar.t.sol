// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { StrChar, StrChar__, StrChar__InvalidUTF8 } from "../src/StrChar.sol";
import { Unicode__InvalidCode } from "../src/utils/unicode.sol";

contract StrCharTest is PRBTest {
    StrCharRevertHelper revertHelper;

    function setUp() public {
        revertHelper = new StrCharRevertHelper();
    }

    function testCmp(uint32 _a, uint32 _b) public {
        vm.assume(
            !(0xD800 <= _a && _a <= 0xDFFF) && _a <= 0x10FFFF
            && !(0xD800 <= _b && _b <= 0xDFFF) && _b <= 0x10FFFF
        );
        StrChar a = StrChar__.fromCodePoint(_a);
        StrChar b = StrChar__.fromCodePoint(_b);

        if (_a < _b) {
            assertTrue(a.cmp(b) < 0);
            assertFalse(a.eq(b));
            assertTrue(a.ne(b));
            assertTrue(a.lt(b));
            assertTrue(a.lte(b));
            assertFalse(a.gt(b));
            assertFalse(a.gte(b));
        } else if (_a > _b) {
            assertTrue(a.cmp(b) > 0);
            assertFalse(a.eq(b));
            assertTrue(a.ne(b));
            assertFalse(a.lt(b));
            assertFalse(a.lte(b));
            assertTrue(a.gt(b));
            assertTrue(a.gte(b));
        } else if (_a == _b) {
            assertTrue(a.cmp(b) == 0);
            assertTrue(a.eq(b));
            assertFalse(a.ne(b));
            assertFalse(a.lt(b));
            assertTrue(a.lte(b));
            assertFalse(a.gt(b));
            assertTrue(a.gte(b));
        }
    }

    function testCmp__Manual() public {
        StrChar a = StrChar__.fromCodePoint(0x00);
        StrChar b = StrChar__.fromCodePoint(0x01);
        assertTrue(a.cmp(b) < 0);
        assertFalse(a.eq(b));
        assertTrue(a.ne(b));
        assertTrue(a.lt(b));
        assertTrue(a.lte(b));
        assertFalse(a.gt(b));
        assertFalse(a.gte(b));

        a = StrChar__.fromCodePoint(0x757);
        b = StrChar__.fromCodePoint(0x7);
        assertTrue(a.cmp(b) > 0);
        assertFalse(a.eq(b));
        assertTrue(a.ne(b));
        assertFalse(a.lt(b));
        assertFalse(a.lte(b));
        assertTrue(a.gt(b));
        assertTrue(a.gte(b));

        a = StrChar__.fromCodePoint(0x10FFFF);
        b = StrChar__.fromCodePoint(0x10FFFF);
        assertTrue(a.cmp(b) == 0);
        assertTrue(a.eq(b));
        assertFalse(a.ne(b));
        assertFalse(a.lt(b));
        assertTrue(a.lte(b));
        assertFalse(a.gt(b));
        assertTrue(a.gte(b));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        1 BYTE
    //////////////////////////////////////////////////////////////////////////*/

    function testOneByte() public {
        for (uint256 i; i < 0x80; i++) {
            StrChar char = StrChar__.fromCodePoint(i);
            assertTrue(char.isValidUtf8());
            assertEq(char.len(), 1);
            assertEq(char.toCodePoint(), i);
            assertEq(uint256(uint8(char.toBytes32()[0])), i);
            assertEq(uint256(uint8(bytes(char.toString())[0])), i);
        }
    }

    function testOneByte__Invalid() public {
        for (uint256 i = 0x80; i < 0x100; i++) {
            vm.expectRevert(StrChar__InvalidUTF8.selector);
            revertHelper.from(bytes32(i << 248));
        }
    }

    // anything after a valid UTF-8 character is ignored
    function testOneByte__Trailing() public {
        assertEq(StrChar__.from(bytes32(hex"0080")).toCodePoint(), 0);
        assertEq(StrChar__.from(bytes32(hex"0011111111")).toCodePoint(), 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        2 BYTES
    //////////////////////////////////////////////////////////////////////////*/

    function testTwoByte() public {
        for (uint256 i = 0x80; i < 0x800; i++) {
            StrChar char = StrChar__.fromCodePoint(i);
            assertTrue(char.isValidUtf8());
            assertEq(char.len(), 2);
            assertEq(char.toCodePoint(), i);
        }
    }

    // testing against solidity's own encoder
    function testTwoByte__Manual() public {
        assertEq(StrChar__.fromCodePoint(0x80).toBytes32(),  bytes32("\u0080"));
        assertEq(StrChar__.fromCodePoint(0x80).toString(),    string("\u0080"));
        assertEq(StrChar__.fromCodePoint(0x81).toBytes32(),  bytes32("\u0081"));
        assertEq(StrChar__.fromCodePoint(0x81).toString(),    string("\u0081"));
        assertEq(StrChar__.fromCodePoint(0x100).toBytes32(), bytes32("\u0100"));
        assertEq(StrChar__.fromCodePoint(0x100).toString(),   string("\u0100"));
        assertEq(StrChar__.fromCodePoint(0x101).toBytes32(), bytes32("\u0101"));
        assertEq(StrChar__.fromCodePoint(0x101).toString(),   string("\u0101"));
        assertEq(StrChar__.fromCodePoint(0x256).toBytes32(), bytes32("\u0256"));
        assertEq(StrChar__.fromCodePoint(0x256).toString(),   string("\u0256"));
        assertEq(StrChar__.fromCodePoint(0x600).toBytes32(), bytes32("\u0600"));
        assertEq(StrChar__.fromCodePoint(0x600).toString(),   string("\u0600"));
        assertEq(StrChar__.fromCodePoint(0x799).toBytes32(), bytes32("\u0799"));
        assertEq(StrChar__.fromCodePoint(0x799).toString(),   string("\u0799"));
    }

    function testTwoByte__Invalid() public {
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"E000"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"E555"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"FFFF"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"C000"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"C080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"C0C0"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"C190"));
    }

    function testTwoByte__Trailing() public {
        assertEq(StrChar__.from(bytes32(hex"C280111111")).toCodePoint(), 0x80);
        assertEq(StrChar__.from(bytes32(hex"C28000FFFF")).toCodePoint(), 0x80);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        3 BYTES
    //////////////////////////////////////////////////////////////////////////*/

    function testThreeByte() public {
        for (uint256 i = 0x800; i < 0x10000; i++) {
            if (0xD800 <= i && i <= 0xDFFF) {
                // skip surrogate halves
                continue;
            }
            StrChar char = StrChar__.fromCodePoint(i);
            assertTrue(char.isValidUtf8());
            assertEq(char.len(), 3);
            assertEq(char.toCodePoint(), i);
        }
    }

    function testThreeByte__InvalidSurrogateHalf() public {
        for (uint256 i = 0xD800; i <= 0xDFFF; i++) {
            vm.expectRevert(Unicode__InvalidCode.selector);
            revertHelper.fromCodePoint(i);
        }
    }

    function testThreeByte__Manual() public {
        assertEq(StrChar__.fromCodePoint(0x800).toBytes32(),  bytes32("\u0800"));
        assertEq(StrChar__.fromCodePoint(0x800).toString(),    string("\u0800"));
        assertEq(StrChar__.fromCodePoint(0x801).toBytes32(),  bytes32("\u0801"));
        assertEq(StrChar__.fromCodePoint(0x801).toString(),    string("\u0801"));
        assertEq(StrChar__.fromCodePoint(0x999).toBytes32(),  bytes32("\u0999"));
        assertEq(StrChar__.fromCodePoint(0x999).toString(),    string("\u0999"));
        assertEq(StrChar__.fromCodePoint(0xFFF).toBytes32(),  bytes32("\u0FFF"));
        assertEq(StrChar__.fromCodePoint(0xFFF).toString(),    string("\u0FFF"));
        assertEq(StrChar__.fromCodePoint(0x1000).toBytes32(), bytes32("\u1000"));
        assertEq(StrChar__.fromCodePoint(0x1000).toString(),   string("\u1000"));
        assertEq(StrChar__.fromCodePoint(0x1001).toBytes32(), bytes32("\u1001"));
        assertEq(StrChar__.fromCodePoint(0x1001).toString(),   string("\u1001"));
        assertEq(StrChar__.fromCodePoint(0x2500).toBytes32(), bytes32("\u2500"));
        assertEq(StrChar__.fromCodePoint(0x2500).toString(),   string("\u2500"));
        assertEq(StrChar__.fromCodePoint(0xD799).toBytes32(), bytes32("\uD799"));
        assertEq(StrChar__.fromCodePoint(0xD799).toString(),   string("\uD799"));
        assertEq(StrChar__.fromCodePoint(0xE000).toBytes32(), bytes32("\uE000"));
        assertEq(StrChar__.fromCodePoint(0xE000).toString(),   string("\uE000"));
        assertEq(StrChar__.fromCodePoint(0xF0FF).toBytes32(), bytes32("\uF0FF"));
        assertEq(StrChar__.fromCodePoint(0xF0FF).toString(),   string("\uF0FF"));
        assertEq(StrChar__.fromCodePoint(0xFFFF).toBytes32(), bytes32("\uFFFF"));
        assertEq(StrChar__.fromCodePoint(0xFFFF).toString(),   string("\uFFFF"));
    }

    function testThreeByte__Invalid() public {
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F00000"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F08080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"FFFFFF"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"E08080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"E09F80"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"E0C080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"E0A07F"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"EDA080"));
    }

    function testThreeByte__Trailing() public {
        assertEq(StrChar__.from(bytes32(hex"E0A0801111")).toCodePoint(), 0x800);
        assertEq(StrChar__.from(bytes32(hex"E0A08000FF")).toCodePoint(), 0x800);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        4 BYTES
    //////////////////////////////////////////////////////////////////////////*/

    function testFourByte() public {
        // it's a ~million, don't really want to loop the whole thing (takes like 15 secs),
        // so just take 65k from each side 
        for (uint256 i = 0x10000; i < 0x20000; i++) {
            StrChar char = StrChar__.fromCodePoint(i);
            assertTrue(char.isValidUtf8());
            assertEq(char.len(), 4);
            assertEq(char.toCodePoint(), i);
        }
        for (uint256 i = 0x100000; i <= 0x10FFFF; i++) {
            StrChar char = StrChar__.fromCodePoint(i);
            assertTrue(char.isValidUtf8());
            assertEq(char.len(), 4);
            assertEq(char.toCodePoint(), i);
        }
    }

    function testFourByte__Manual() public {
        // solidity's \u doesn't work with 4-byte code points :(
        assertEq(StrChar__.fromCodePoint(0x10000).toBytes32(),  unicode"𐀀");
        assertEq(StrChar__.fromCodePoint(0x10000).toString(),   unicode"𐀀");
        assertEq(StrChar__.fromCodePoint(0x10001).toBytes32(),  unicode"𐀁");
        assertEq(StrChar__.fromCodePoint(0x10001).toString(),   unicode"𐀁");
        assertEq(StrChar__.fromCodePoint(0x20000).toBytes32(),  unicode"𠀀");
        assertEq(StrChar__.fromCodePoint(0x20000).toString(),   unicode"𠀀");
        assertEq(StrChar__.fromCodePoint(0x34567).toBytes32(),  unicode"𴕧");
        assertEq(StrChar__.fromCodePoint(0x34567).toString(),   unicode"𴕧");
        assertEq(StrChar__.fromCodePoint(0xF0000).toBytes32(),  unicode"󰀀");
        assertEq(StrChar__.fromCodePoint(0xF0000).toString(),   unicode"󰀀");
        assertEq(StrChar__.fromCodePoint(0xFFFFF).toBytes32(),  unicode"󿿿");
        assertEq(StrChar__.fromCodePoint(0xFFFFF).toString(),   unicode"󿿿");
        assertEq(StrChar__.fromCodePoint(0x100000).toBytes32(), unicode"􀀀");
        assertEq(StrChar__.fromCodePoint(0x100000).toString(),  unicode"􀀀");
        assertEq(StrChar__.fromCodePoint(0x10FFFF).toBytes32(), unicode"􏿿");
        assertEq(StrChar__.fromCodePoint(0x10FFFF).toString(),  unicode"􏿿");
    }

    function testFourByte__Invalid() public {
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F0000000"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F0808080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"FFFFFFFF"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F08F8080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F0C08080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F17F8080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F4908080"));
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        revertHelper.from(bytes32(hex"F4BF8080"));
    }

    function testFourByte__Trailing() public {
        assertEq(StrChar__.from(bytes32(hex"F09080801111")).toCodePoint(), 0x10000);
        assertEq(StrChar__.from(bytes32(hex"F090808000FF")).toCodePoint(), 0x10000);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASCII
    //////////////////////////////////////////////////////////////////////////*/

    function testIsAscii() public {
        for (uint256 i; i < 0x80; i++) {
            assertTrue(StrChar__.fromCodePoint(i).isAscii());
        }

        for (uint256 i = 0x80; i < 0x20000; i++) {
            if (0xD800 <= i && i <= 0xDFFF) {
                // skip surrogate halves
                continue;
            }
            assertFalse(StrChar__.fromCodePoint(i).isAscii());
        }
        assertFalse(StrChar__.fromCodePoint(0x10FFFF).isAscii());
    }
}

contract StrCharRevertHelper {
    function from(bytes32 b) public pure returns (StrChar char) {
        return StrChar__.from(b);
    }

    function fromCodePoint(uint256 code) public pure returns (StrChar char) {
        return StrChar__.fromCodePoint(code);
    }
}