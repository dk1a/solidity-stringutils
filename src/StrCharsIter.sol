// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice } from "./Slice.sol";
import { StrSlice } from "./StrSlice.sol";
import { SliceIter, SliceIter__, SliceIter__StopIteration } from "./SliceIter.sol";
import { StrChar, StrChar__, StrChar__InvalidUTF8 } from "./StrChar.sol";

/**
 * @title String chars iterator.
 * @dev This struct is created by the iter method on `StrSlice`.
 * Iterates 1 UTF-8 encoded character at a time (which may have 1-4 bytes).
 *
 * Note StrCharsIter iterates over UTF-8 encoded codepoints, not unicode scalar values.
 * This is mostly done for simplicity, since solidity doesn't care about unicode anyways.
 *
 * TODO think about actually adding char and unicode awareness?
 * https://github.com/devstein/unicode-eth attempts something like that
 */
struct StrCharsIter {
    uint256 _ptr;
    uint256 _len;
}

/*//////////////////////////////////////////////////////////////////////////
                                STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrCharsIter__ {
    /**
     * @dev Creates a new `StrCharsIter` from `StrSlice`.
     * Note the `StrSlice` is assumed to be memory-safe.
     */
    function from(StrSlice slice) internal pure returns (StrCharsIter memory) {
        return StrCharsIter(slice.ptr(), slice.len());

        // TODO I'm curious about gas differences
        // return StrCharsIter(SliceIter__.from(str.asSlice()));
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asStr,
    ptr, len, isEmpty,
    next, nextBack,
    count
} for StrCharsIter global;

/**
 * @dev Views the underlying data as a subslice of the original data.
 */
function asStr(StrCharsIter memory self) pure returns (StrSlice slice) {
    return StrSlice.wrap(Slice.unwrap(
        self._sliceIter().asSlice()
    ));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrCharsIter memory self) pure returns (uint256) {
    return self._ptr;
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrCharsIter memory self) pure returns (uint256) {
    return self._len;
}

/**
 * @dev Returns true if the iterator is empty.
 */
function isEmpty(StrCharsIter memory self) pure returns (bool) {
    return self._sliceIter().isEmpty();
}

/**
 * @dev Advances the iterator and returns the next character.
 * Reverts if len == 0.
 */
function next(StrCharsIter memory self) pure returns (StrChar char) {
    if (self.len() == 0) revert SliceIter__StopIteration();

    bytes32 b = self._sliceIter().asSlice().toBytes32();
    // Reverts if can't make valid UTF-8
    char = StrChar__.from(b);

    // advance the iterator
    // TODO this can probably be unchecked (toBytes32 zeros overflow, and selfLen != 0 so \0 can be a char too)
    self._ptr += char.len();
    self._len -= char.len();

    return char;
}

/**
 * @dev Advances the iterator from the back and returns the next character.
 * Reverts if len == 0.
 */
function nextBack(StrCharsIter memory self) pure returns (StrChar char) {
    if (self.len() == 0) revert SliceIter__StopIteration();

    // _self shares memory with self!
    SliceIter memory _self = self._sliceIter();

    bool isValid;
    uint256 b;
    for (uint256 i; i < 4; i++) {
        // an example of what's going on in the loop:
        // b = 0x000000..0000
        // nextBack = 0xAB
        // b = 0xAB0000..0000
        // nextBack = 0xCD
        // b = 0xABCD00..0000
        // ...2 more times

        b = b | (
            // get 1 byte in LSB
            uint256(_self.nextBack())
            // flip it to MSB
            << ((31 - i) * 8)
        );
        // break if the char is valid
        char = StrChar__.fromUnchecked(bytes32(b));
        isValid = char.isValidUtf8();
        if (isValid) break;
    }
    if (!isValid) revert StrChar__InvalidUTF8();

    // advance the iterator
    self._len -= char.len();
    // fromUnchecked was safe, because UTF-8 was validated,
    // and all the remaining bytes are 0 (since the loop went byte-by-byte)
    return char;
}

/**
 * @dev Consumes the iterator, counting the number of UTF-8 characters.
 * Note O(n) time!
 * Reverts on invalid UTF-8.
 */
function count(StrCharsIter memory self) pure returns (uint256 result) {
    while (!self.isEmpty()) {
        self.next();
        result += 1;
    }
    return result;
}

/*//////////////////////////////////////////////////////////////////////////
                            FILE-LEVEL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using { _sliceIter } for StrCharsIter;

/**
 * @dev Returns the underlying `SliceIter`.
 * AVOID USING THIS EXTERNALLY!
 * Advancing the underlying slice could lead to invalid UTF-8 for StrCharsIter.
 */
function _sliceIter(StrCharsIter memory self) pure returns (SliceIter memory result) {
    assembly {
        result := self
    }
}