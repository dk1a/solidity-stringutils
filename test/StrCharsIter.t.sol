// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { StrSlice, toSlice, StrCharsIter } from "../src/StrSlice.sol";
import { SliceIter__StopIteration } from "../src/SliceIter.sol";
import { StrChar__InvalidUTF8 } from "../src/StrChar.sol";

using { toSlice } for string;

contract StrCharsIterTest is PRBTest {
    function testCount() public {
        assertEq(toSlice("").chars().count(), 0);
        assertEq(toSlice("Hello, world!").chars().count(), 13);
        assertEq(toSlice(unicode"naïve").chars().count(), 5);
        assertEq(toSlice(unicode"こんにちは").chars().count(), 5);
        assertEq(toSlice(unicode"Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇").chars().count(), 56);
        assertEq(toSlice(unicode"🗮🐵🌝👤👿🗉💀🉄🍨🉔🈥🔥🏅🔪🉣📷🉳🍠🈃🉌🖷👍🌐💎🋀🌙💼💮🗹🗘💬🖜🐥🖸🈰🍦💈📆🋬🏇🖒🐜👮🊊🗒🈆🗻🏁🈰🎎🊶🉠🍖🉪🌖📎🌄💵🕷🔧🍸🋗🍁🋸")
            .chars().count(), 64);
    }

    function testUnsafeCount() public {
        assertEq(toSlice("").chars().unsafeCount(), 0);
        assertEq(toSlice("Hello, world!").chars().unsafeCount(), 13);
        assertEq(toSlice(unicode"naïve").chars().unsafeCount(), 5);
        assertEq(toSlice(unicode"こんにちは").chars().unsafeCount(), 5);
        assertEq(toSlice(unicode"Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇").chars().unsafeCount(), 56);
        assertEq(toSlice(unicode"🗮🐵🌝👤👿🗉💀🉄🍨🉔🈥🔥🏅🔪🉣📷🉳🍠🈃🉌🖷👍🌐💎🋀🌙💼💮🗹🗘💬🖜🐥🖸🈰🍦💈📆🋬🏇🖒🐜👮🊊🗒🈆🗻🏁🈰🎎🊶🉠🍖🉪🌖📎🌄💵🕷🔧🍸🋗🍁🋸")
            .chars().unsafeCount(), 64);
    }

    function testValidateUtf8() public {
        assertTrue(toSlice("").chars().validateUtf8());
        assertTrue(toSlice("Hello, world!").chars().validateUtf8());
        assertTrue(toSlice(unicode"naïve").chars().validateUtf8());
        assertTrue(toSlice(unicode"こんにちは").chars().validateUtf8());
        assertTrue(toSlice(unicode"Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇").chars().validateUtf8());
        assertTrue(toSlice(unicode"🗮🐵🌝👤👿🗉💀🉄🍨🉔🈥🔥🏅🔪🉣📷🉳🍠🈃🉌🖷👍🌐💎🋀🌙💼💮🗹🗘💬🖜🐥🖸🈰🍦💈📆🋬🏇🖒🐜👮🊊🗒🈆🗻🏁🈰🎎🊶🉠🍖🉪🌖📎🌄💵🕷🔧🍸🋗🍁🋸")
            .chars().validateUtf8());
    }

    function testValidateUtf8__False() public {
        assertFalse(toSlice(string(bytes(hex"80"))).chars().validateUtf8());
        assertFalse(toSlice(string(bytes(hex"E0"))).chars().validateUtf8());
        assertFalse(toSlice(string(bytes(hex"C000"))).chars().validateUtf8());
        assertFalse(toSlice(string(bytes(hex"F880808080"))).chars().validateUtf8());
        assertFalse(toSlice(string(bytes(hex"E08080"))).chars().validateUtf8());
        assertFalse(toSlice(string(bytes(hex"F0808080"))).chars().validateUtf8());
        assertFalse(toSlice(string(abi.encodePacked(unicode"こんにちは", hex"80"))).chars().validateUtf8());
        assertFalse(toSlice(string(abi.encodePacked(unicode"Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇Z̤͔ͧ̑̓ä͖̭̈̇lͮ̒ͫǧ̗͚̚o̙̔ͮ̇͐̇", hex"F0808080"))).chars().validateUtf8());
    }

    function testCount__InvalidUTF8() public {
        vm.expectRevert(StrChar__InvalidUTF8.selector);
        toSlice(string(bytes(hex"FFFF"))).chars().count();
    }

    function testNext() public {
        StrSlice s = string(unicode"a¡ࠀ𐀡").toSlice();
        StrCharsIter memory iter = s.chars();

        assertEq(iter.next().toString(), unicode"a");
        assertEq(iter.asStr().toString(), unicode"¡ࠀ𐀡");
        assertEq(iter.next().toString(), unicode"¡");
        assertEq(iter.asStr().toString(), unicode"ࠀ𐀡");
        assertEq(iter.next().toString(), unicode"ࠀ");
        assertEq(iter.asStr().toString(), unicode"𐀡");
        assertEq(iter.next().toString(), unicode"𐀡");
        assertEq(iter.asStr().toString(), unicode"");
    }

    function testNext__StopIteration() public {
        StrSlice s = string(unicode"💀!").toSlice();
        StrCharsIter memory iter = s.chars();

        iter.next();
        iter.next();
        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }

    function testNextBack() public {
        StrSlice s = string(unicode"a¡ࠀ𐀡").toSlice();
        StrCharsIter memory iter = s.chars();

        assertEq(iter.nextBack().toString(), unicode"𐀡");
        assertEq(iter.asStr().toString(), unicode"a¡ࠀ");
        assertEq(iter.nextBack().toString(), unicode"ࠀ");
        assertEq(iter.asStr().toString(), unicode"a¡");
        assertEq(iter.nextBack().toString(), unicode"¡");
        assertEq(iter.asStr().toString(), unicode"a");
        assertEq(iter.nextBack().toString(), unicode"a");
        assertEq(iter.asStr().toString(), unicode"");
    }

    function testNextBack__StopIteration() public {
        StrSlice s = string(unicode"💀!").toSlice();
        StrCharsIter memory iter = s.chars();

        iter.nextBack();
        iter.nextBack();
        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.nextBack();
    }

    function testUnsafeNext() public {
        StrSlice s = string(unicode"a¡ࠀ𐀡").toSlice();
        StrCharsIter memory iter = s.chars();

        assertEq(iter.unsafeNext().toString(), unicode"a");
        assertEq(iter.asStr().toString(), unicode"¡ࠀ𐀡");
        assertEq(iter.unsafeNext().toString(), unicode"¡");
        assertEq(iter.asStr().toString(), unicode"ࠀ𐀡");
        assertEq(iter.unsafeNext().toString(), unicode"ࠀ");
        assertEq(iter.asStr().toString(), unicode"𐀡");
        assertEq(iter.unsafeNext().toString(), unicode"𐀡");
        assertEq(iter.asStr().toString(), unicode"");
    }

    function testUnsafeNext__InvalidUtf8() public {
        StrSlice s = string(bytes(hex"00FF80")).toSlice();
        StrCharsIter memory iter = s.chars();

        // this works kinda weirdly for invalid chars
        // TODO test toBytes32 too (it will be non-empty here)
        assertEq(iter.unsafeNext().toString(), string(bytes(hex"00")));
        assertEq(iter.asStr().toString(), string(bytes(hex"FF80")));
        assertEq(iter.unsafeNext().toString(), "");
        assertEq(iter.asStr().toString(), string(bytes(hex"80")));
        assertEq(iter.unsafeNext().toString(), "");
        assertEq(iter.asStr().toString(), "");
    }
}