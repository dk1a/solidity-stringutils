// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice } from "./Slice.sol";
import { StrSlice } from "./StrSlice.sol";
import { SliceIter, SliceIter__, SliceIter__StopIteration } from "./SliceIter.sol";
import { StrChar, StrChar__, StrChar__InvalidUTF8 } from "./StrChar.sol";
import { isValidUtf8 } from "./utils/utf8.sol";

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
    next, nextBack, unsafeNext,
    count, validateUtf8
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
    return self._len == 0;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Reverts if len == 0.
 */
function next(StrCharsIter memory self) pure returns (StrChar char) {
    if (self._len == 0) revert SliceIter__StopIteration();

    bytes32 b = self._sliceIter().asSlice().toBytes32();
    // Reverts if can't make valid UTF-8
    char = StrChar__.from(b);

    // advance the iterator
    // safe because selfLen != 0, toBytes32 zeros overflow, StrChar__.from reverts for invalid chars
    unchecked {
        uint256 charLen = char.len();
        self._ptr += charLen;
        self._len -= charLen;
    }

    return char;
}

/**
 * @dev Advances the iterator from the back and returns the next character.
 * Reverts if len == 0.
 */
function nextBack(StrCharsIter memory self) pure returns (StrChar char) {
    if (self._len == 0) revert SliceIter__StopIteration();

    // _self shares memory with self!
    SliceIter memory _self = self._sliceIter();

    bool isValid;
    uint256 b;
    for (uint256 i; i < 4; i++) {
        // an example of what's going on in the loop:
        // b = 0x0000000000..00
        // nextBack = 0x80
        // b = 0x8000000000..00 (not valid UTF-8)
        // nextBack = 0x92
        // b = 0x9280000000..00 (not valid UTF-8)
        // nextBack = 0x9F
        // b = 0x9F92800000..00 (not valid UTF-8)
        // nextBack = 0xF0
        // b = 0xF09F928000..00 (valid UTF-8, break)

        // safe because i < 4
        unchecked {
            // free the space in MSB
            b = (b >> 8) | (
                // get 1 byte in LSB
                uint256(_self.nextBack())
                // flip it to MSB
                << (31 * 8)
            );
        }
        // break if the char is valid
        isValid = isValidUtf8(bytes32(b));
        if (isValid) break;
    }
    if (!isValid) revert StrChar__InvalidUTF8();

    // construct the character;
    // wrap is safe, because UTF-8 was validated,
    // and the trailing bytes are 0 (since the loop went byte-by-byte)
    char = StrChar.wrap(bytes32(b));
    // the iterator was already advanced by `_self.nextBack()`
    return char;
}

/**
 * @dev Advances the iterator and returns the next character.
 * Does NOT validate UTF-8.
 * WARNING: skips invalid bytes and returns invalid `StrChar` with len 0 for them!
 */
function unsafeNext(StrCharsIter memory self) pure returns (StrChar char) {
    if (self._len == 0) revert SliceIter__StopIteration();

    bytes32 b = self._sliceIter().asSlice().toBytes32();
    // Does NOT revert on invalid UTF-8
    char = StrChar.wrap(b);

    // advance the iterator
    // overflow-safe because charLen won't add up to more than byte length (i.e. self._len),
    // but unsafe for UTF-8, because it just skips invalid bytes
    unchecked {
        uint256 charLen = char.len();
        if (charLen == 0) {
            self._ptr += 1;
            self._len -= 1;
        } else {
            self._ptr += charLen;
            self._len -= charLen;
        }
    }

    return char;
}

/**
 * @dev Consumes the iterator, counting the number of UTF-8 characters.
 * Note O(n) time!
 * Reverts on invalid UTF-8.
 */
function count(StrCharsIter memory self) pure returns (uint256 result) {
    while (self._len != 0) {
        self.next();
        // safe because 2**256 cycles are impossible (or that much memory allocation)
        unchecked {
            result += 1;
        }
    }
    return result;
}

/**
 * @dev Consumes the iterator, validating UTF-8 characters.
 * Note O(n) time!
 * Returns true if all are valid; otherwise false on the first invalid UTF-8 character.
 */
function validateUtf8(StrCharsIter memory self) pure returns (bool) {
    while (self._len != 0) {
        StrChar char = self.unsafeNext();
        if (!char.isValidUtf8()) return false;
    }
    return true;
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