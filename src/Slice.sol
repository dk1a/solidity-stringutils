// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { mload8, memcpy, memcmp, memeq, leftMask } from "./utils/mem.sol";
import { memchr, memrchr } from "./utils/memchr.sol";
import { PackPtrLen } from "./utils/PackPtrLen.sol";

import { SliceIter, SliceIter__ } from "./SliceIter.sol";

/**
 * @title A view into a contiguous sequence of 1-byte items.
 * TODO other item types
 */
type Slice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error Slice__OutOfBounds();
error Slice__LengthMismatch();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library Slice__ {
    /**
     * @dev Converts a `bytes` to a `Slice`.
     * The bytes are not copied.
     * `Slice` points to the memory of `bytes`, right after the length word.
     */
    function from(bytes memory b) internal pure returns (Slice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(b, 0x20)
        }
        return fromRawParts(_ptr, b.length);
    }

    /**
     * @dev Creates a new `Slice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (Slice slice) {
        return Slice.wrap(PackPtrLen.pack(_ptr, _len));
    }
}

/**
 * @dev Alternative to Slice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for bytes;
 * ```
 */
function toSlice(bytes memory b) pure returns (Slice slice) {
    return Slice__.from(b);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    ptr, len, isEmpty,
    // conversion
    toBytes, toBytes32,
    keccak,
    // concatenation
    add, join,
    // copy
    copyFromSlice,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    get, first, last,
    splitAt, getSubslice, getBefore, getAfter, getAfterStrict,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    // iteration
    iter
} for Slice global;

/**
 * @dev Returns the pointer to the start of an in-memory slice.
 */
function ptr(Slice self) pure returns (uint256) {
    return PackPtrLen.getPtr(Slice.unwrap(self));
}

/**
 * @dev Returns the length in bytes.
 */
function len(Slice self) pure returns (uint256) {
    return PackPtrLen.getLen(Slice.unwrap(self));
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(Slice self) pure returns (bool) {
    return self.len() == 0;
}

/**
 * @dev Copies `Slice` to a new `bytes`.
 * The `Slice` will NOT point to the new `bytes`.
 */
function toBytes(Slice self) pure returns (bytes memory b) {
    b = new bytes(self.len());
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memcpy(bPtr, self.ptr(), self.len());
    return b;
}

/**
 * @dev Fills a `bytes32` (value type) with the first 32 bytes of `Slice`.
 * Goes from left(MSB) to right(LSB).
 * If len < 32, the leftover bytes are zeros.
 */
function toBytes32(Slice self) pure returns (bytes32 b) {
    uint256 selfPtr = self.ptr();

    // mask removes any trailing bytes
    uint256 selfLen = self.len();
    uint256 mask = leftMask(selfLen > 32 ? 32 : selfLen);

    /// @solidity memory-safe-assembly
    assembly {
        b := and(mload(selfPtr), mask)
    }
    return b;
}

/**
 * @dev Returns keccak256 of all the bytes of `Slice`.
 * Note that for any `bytes memory b`, keccak256(b) == b.toSlice().keccak()
 * (keccak256 does not include the length byte)
 */
function keccak(Slice self) pure returns (bytes32 result) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    /// @solidity memory-safe-assembly
    assembly {
        result := keccak256(selfPtr, selfLen)
    }
}

/**
 * @dev Concatenates two `Slice`s into a newly allocated `bytes`.
 */
function add(Slice self, Slice other) pure returns (bytes memory b) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();

    b = new bytes(selfLen + otherLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }

    memcpy(bPtr, self.ptr(), selfLen);
    memcpy(bPtr + selfLen, other.ptr(), otherLen);
    return b;
}

/**
 * @dev Flattens an array of `Slice`s into a single newly allocated `bytes`,
 * placing `self` as the separator between each.
 *
 * TODO this is the wrong place for this method, but there are no other places atm
 * (since there's no proper chaining/reducers/anything)
 */
function join(Slice self, Slice[] memory slices) pure returns (bytes memory b) {
    uint256 slicesLen = slices.length;
    if (slicesLen == 0) return "";

    uint256 repetitionLen;
    // -1 is safe because of ==0 check earlier
    unchecked {
        repetitionLen = slicesLen - 1;
    }
    // add separator repetitions length
    uint256 totalLen = self.len() * repetitionLen;
    // add slices length
    for (uint256 i; i < slicesLen; i++) {
        totalLen += slices[i].len();
    }

    b = new bytes(totalLen);
    uint256 bPtr;
    assembly {
        bPtr := add(b, 0x20)
    }
    for (uint256 i; i < slicesLen; i++) {
        Slice slice = slices[i];
        // copy slice
        memcpy(bPtr, slice.ptr(), slice.len());
        bPtr += slice.len();
        // copy separator (skips the last cycle)
        if (i < repetitionLen) {
            memcpy(bPtr, self.ptr(), self.len());
            bPtr += self.len();
        }
    }
}

/**
 * @dev Copies all elements from `src` into `self`.
 * The length of `src` must be the same as `self`.
 */
function copyFromSlice(Slice self, Slice src) pure {
    if (self.len() != src.len()) revert Slice__LengthMismatch();

    memcpy(self.ptr(), src.ptr(), src.len());
}

/**
 * @dev Compare slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(Slice self, Slice other) pure returns (int256 result) {
    uint256 selfLen = self.len();
    uint256 otherLen = other.len();
    uint256 minLen = selfLen < otherLen ? selfLen : otherLen;

    result = memcmp(self.ptr(), other.ptr(), minLen);

    if (result == 0) {
        // the longer slice is greater than its prefix
        // (lengths take only 16 bytes, so signed sub is safe)
        unchecked {
            return int256(selfLen) - int256(otherLen);
        }
    }

    return result;
}

/// @dev self == other
/// Note more efficient than cmp for big slices
function eq(Slice self, Slice other) pure returns (bool) {
    if (self.len() != other.len()) return false;
    return memeq(self.ptr(), other.ptr(), self.len());
}

/// @dev self != other
/// Note more efficient than cmp for big slices
function ne(Slice self, Slice other) pure returns (bool) {
    if (self.len() != other.len()) return true;
    return !memeq(self.ptr(), other.ptr(), self.len());
}

/// @dev `self` < `other`
function lt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(Slice self, Slice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Returns the byte at `index`.
 * Reverts if index is out of bounds.
 */
function get(Slice self, uint256 index) pure returns (uint8 item) {
    if (index >= self.len()) revert Slice__OutOfBounds();

    // ptr and len are uint128 (because PackPtrLen); index < len
    unchecked {
        return mload8(self.ptr() + index);
    }
}

/**
 * @dev Returns the first byte of the slice.
 * Reverts if the slice is empty.
 */
function first(Slice self) pure returns (uint8 item) {
    return self.get(0);
}

/**
 * @dev Returns the last byte of the slice.
 * Reverts if the slice is empty.
 */
function last(Slice self) pure returns (uint8 item) {
    // on 0-1 overflow get will revert with out of bounds, as intended
    unchecked {
        return self.get(self.len() - 1);
    }
}

/**
 * @dev Divides one slice into two at an index.
 */
function splitAt(Slice self, uint256 mid) pure returns (Slice, Slice) {
    uint256 selfPtr = self.ptr();
    uint256 selfLen = self.len();
    if (mid > selfLen) revert Slice__OutOfBounds();

    // TODO the 2nd slice being able to get an invalid pointer bothers me,
    // but that only happens if its len is 0 so it's fine?
    return (Slice__.fromRawParts(selfPtr, mid), Slice__.fromRawParts(selfPtr + mid, selfLen - mid));
}

/**
 * @dev Returns a subslice [start:end] of `self`.
 * Reverts if start/end are out of bounds.
 */
function getSubslice(Slice self, uint256 start, uint256 end) pure returns (Slice) {
    if (!(start <= end && end <= self.len())) revert Slice__OutOfBounds();
    // selfPtr + start is safe because start <= selfLen (pointers are implicitly safe)
    // end - start is safe because start <= end
    unchecked {
        return Slice__.fromRawParts(self.ptr() + start, end - start);
    }
}

/**
 * @dev Returns a subslice [:index] of `self`.
 * Reverts if `index` > length.
 */
function getBefore(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    return Slice__.fromRawParts(self.ptr(), index);
}

/**
 * @dev Returns a subslice [index:] of `self`.
 * Reverts if `index` > length.
 */
function getAfter(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index > selfLen) revert Slice__OutOfBounds();
    // safe because index <= selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromRawParts(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns a non-zero subslice [index:] of `self`.
 * Reverts if `index` >= length.
 */
function getAfterStrict(Slice self, uint256 index) pure returns (Slice) {
    uint256 selfLen = self.len();
    if (index >= selfLen) revert Slice__OutOfBounds();
    // safe because index < selfLen (ptr+len is implicitly safe)
    unchecked {
        return Slice__.fromRawParts(self.ptr() + index, selfLen - index);
    }
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(Slice self, Slice pattern) pure returns (uint256) {
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (self.len() == 0 || patLen > self.len()) {
        return type(uint256).max;
    }

    uint256 offsetPtr = self.ptr();
    uint256 offsetLen = self.len();
    uint8 patFirst = pattern.first();
    while (true) {
        uint256 index = memchr(offsetPtr, offsetLen, patFirst);
        // not found
        if (index == type(uint256).max) return type(uint256).max;

        // move pointer to the found byte
        offsetPtr += index;
        offsetLen -= index;
        // can't find, pattern won't fit after index
        if (patLen > offsetLen) {
            return type(uint256).max;
        }

        if (memeq(offsetPtr, pattern.ptr(), patLen)) {
            // found, return offset index
            return (offsetPtr - self.ptr());
        } else if (offsetLen == 1) {
            // not found and this was the last character
            return type(uint256).max;
        } else {
            // not found and can keep going;
            // increment pointer, memchr shouldn't receive what it returned (otherwise infinite loop)
            offsetPtr++;
            offsetLen--;
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(Slice self, Slice pattern) pure returns (uint256) {
    uint256 patLen = pattern.len();
    if (patLen == 0) {
        return 0;
    } else if (self.len() == 0 || patLen > self.len()) {
        return type(uint256).max;
    }

    uint256 offsetLen = self.len();
    uint8 patLast = pattern.last();
    while (true) {
        uint256 endIndex = memrchr(self.ptr(), offsetLen, patLast);
        // not found
        if (endIndex == type(uint256).max) return type(uint256).max;

        // move pointer to the found byte (+1 is safe because index < offsetLen)
        unchecked {
            offsetLen = endIndex + 1;
        }
        // can't find, pattern won't fit after index
        if (patLen > offsetLen) {
            return type(uint256).max;
        }
        // need startIndex, but memrchr returns endIndex
        uint256 startIndex;
        // - is safe because of the check 5 lines back
        unchecked {
            startIndex = offsetLen - patLen;
        }

        // get a ptr to the start of the pattern within self
        uint256 patPtr = self.ptr() + startIndex;

        if (memeq(patPtr, pattern.ptr(), patLen)) {
            // found, return index
            return startIndex;
        } else if (offsetLen == 1) {
            // not found and this was the last character
            return type(uint256).max;
        } else {
            // not found and can keep going;
            // increment pointer, memrchr shouldn't receive what it returned (otherwise infinite loop)
            offsetLen--;
        }
    }
    return type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this `bytes` slice.
 */
function contains(Slice self, Slice pattern) pure returns (bool) {
    return self.find(pattern) != type(uint256).max;
}

/**
 * @dev Returns true if the given pattern matches a prefix of this slice.
 */
function startsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice prefix = self;
    // make prefix's length equal patLen
    if (selfLen > patLen) {
        prefix = self.getSubslice(0, patLen);
    }
    return prefix.eq(pattern);
}

/**
 * @dev Returns true if the given pattern matches a suffix of this slice.
 */
function endsWith(Slice self, Slice pattern) pure returns (bool) {
    uint256 selfLen = self.len();
    uint256 patLen = pattern.len();
    if (selfLen < patLen) return false;

    Slice suffix = self;
    // make suffix's length equal patLen
    if (selfLen > patLen) {
        suffix = self.getSubslice(selfLen - patLen, selfLen);
    }
    return suffix.eq(pattern);
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(Slice self, Slice pattern) pure returns (Slice result) {
    if (pattern.len() == 0) return self;

    if (self.startsWith(pattern)) {
        (, result) = self.splitAt(pattern.len());
        return result;
    } else {
        return self;
    }
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(Slice self, Slice pattern) pure returns (Slice result) {
    if (pattern.len() == 0) return self;

    if (self.endsWith(pattern)) {
        (result, ) = self.splitAt(self.len() - pattern.len());
        return result;
    } else {
        return self;
    }
}

/**
 * @dev Returns an iterator over the slice.
 * The iterator yields items from either side.
 */
function iter(Slice self) pure returns (SliceIter memory) {
    return SliceIter__.from(self);
}