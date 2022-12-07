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

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }

    function testNextBack() public {
        StrSlice s = string(unicode"a¡ࠀ𐀡").toSlice();
        StrCharsIter memory iter = s.chars();

        assertEq(iter.next().toString(), unicode"𐀡");
        assertEq(iter.asStr().toString(), unicode"a¡ࠀ");
        assertEq(iter.next().toString(), unicode"ࠀ");
        assertEq(iter.asStr().toString(), unicode"a¡");
        assertEq(iter.next().toString(), unicode"¡");
        assertEq(iter.asStr().toString(), unicode"a");
        assertEq(iter.next().toString(), unicode"a");
        assertEq(iter.asStr().toString(), unicode"");

        vm.expectRevert(SliceIter__StopIteration.selector);
        iter.next();
    }
}