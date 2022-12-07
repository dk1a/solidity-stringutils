// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Slice, Slice__ } from "./Slice.sol";
import { StrChar, StrChar__ } from "./StrChar.sol";
import { StrCharsIter, StrCharsIter__ } from "./StrCharsIter.sol";
import { isValidUtf8 } from "./utils/utf8.sol";

/**
 * @title A string slice.
 * @dev String slices must always be valid UTF-8.
 * Internally `StrSlice` uses `Slice`, adding only UTF-8 related logic on top.
 */
type StrSlice is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

error StrSlice__InvalidCharBoundary();

/*//////////////////////////////////////////////////////////////////////////
                              STATIC FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

library StrSlice__ {
    /**
     * @dev Converts a `string` to a `StrSlice`.
     * The string is not copied.
     * `StrSlice` points to the memory of `string`, right after the length word.
     */
    function from(string memory str) internal pure returns (StrSlice slice) {
        uint256 _ptr;
        assembly {
            _ptr := add(str, 0x20)
        }
        return fromRawParts(_ptr, bytes(str).length);
    }

    /**
     * @dev Creates a new `StrSlice` directly from length and memory pointer.
     * Note that the caller MUST guarantee memory-safety.
     * This method is primarily for internal use.
     */
    function fromRawParts(uint256 _ptr, uint256 _len) internal pure returns (StrSlice slice) {
        return StrSlice.wrap(Slice.unwrap(
            Slice__.fromRawParts(_ptr, _len)
        ));
    }

    /**
     * @dev Returns true if the byte slice starts with a valid UTF-8 character.
     * Note this does not validate the whole slice.
     */
    function isBoundaryStart(Slice slice) internal pure returns (bool) {
        bytes32 b = slice.copyToBytes32();
        return StrChar__.fromUnchecked(b).isValidUtf8();
    }
}

/**
 * @dev Alternative to StrSlice__.from()
 * Put this in your file (using for global is only for user-defined types):
 * ```
 * using { toSlice } for string;
 * ```
 */
function toSlice(string memory str) pure returns (StrSlice slice) {
    return StrSlice__.from(str);
}

/*//////////////////////////////////////////////////////////////////////////
                              GLOBAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    asSlice,
    ptr, len, isEmpty,
    // concatenation
    add, join,
    // copy
    toString,
    keccak,
    // compare
    cmp, eq, ne, lt, lte, gt, gte,
    // index
    isCharBoundary,
    get,
    splitAt, getSubslice,
    // search
    find, rfind, contains,
    startsWith, endsWith,
    // modify
    stripPrefix, stripSuffix,
    replacen,
    // iteration
    chars
} for StrSlice global;

/**
 * @dev Returns the underlying `Slice`.
 * WARNING: manipulating `Slice`s can break UTF-8 for related `StrSlice`s!
 */
function asSlice(StrSlice self) pure returns (Slice) {
    return Slice.wrap(StrSlice.unwrap(self));
}

/**
 * @dev Returns the pointer to the start of an in-memory string slice.
 * This method is primarily for internal use.
 */
function ptr(StrSlice self) pure returns (uint256) {
    return self.asSlice().ptr();
}

/**
 * @dev Returns the length in bytes, not codepoints.
 */
function len(StrSlice self) pure returns (uint256) {
    return self.asSlice().len();
}

/**
 * @dev Returns true if the slice has a length of 0.
 */
function isEmpty(StrSlice self) pure returns (bool) {
    return self.asSlice().isEmpty();
}

/**
 * @dev Concatenates two `StrSlice`s into a newly allocated string.
 */
function add(StrSlice self, StrSlice other) view returns (string memory) {
    return string(self.asSlice().add(other.asSlice()));
}

/**
 * @dev Flattens an array of `StrSlice`s into a single newly allocated string,
 * placing `self` as the separator between each.
 */
function join(StrSlice self, StrSlice[] memory strs) view returns (string memory) {
    Slice[] memory slices;
    // TODO is there another way to unwrap arrays of user-defined types?
    assembly {
        slices := strs
    }
    return string(self.asSlice().join(slices));
}

/**
 * @dev Copies `StrSlice` to a newly allocated string.
 * The `StrSlice` will NOT point to the new string.
 */
function toString(StrSlice self) view returns (string memory) {
    return string(self.asSlice().copyToBytes());
}

/**
 * @dev Returns keccak256 of all the bytes of `StrSlice`.
 * Note `StrSlice` hashes will never equal `string` hashes,
 * because `string` always stores length in-memory, but `StrSlice` never includes it.
 */
function keccak(StrSlice self) pure returns (bytes32 result) {
    return self.asSlice().keccak();
}

/**
 * @dev Compare string slices lexicographically.
 * @return result 0 for equal, < 0 for less than and > 0 for greater than.
 */
function cmp(StrSlice self, StrSlice other) pure returns (int result) {
    return self.asSlice().cmp(other.asSlice());
}

/// @dev `self` == `other`
/// Note more efficient than cmp for big slices
function eq(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().eq(other.asSlice());
}

/// @dev `self` != `other`
/// Note more efficient than cmp for big slices
function ne(StrSlice self, StrSlice other) pure returns (bool) {
    return self.asSlice().ne(other.asSlice());
}

/// @dev `self` < `other`
function lt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) < 0;
}

/// @dev `self` <= `other`
function lte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) <= 0;
}

/// @dev `self` > `other`
function gt(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) > 0;
}

/// @dev `self` >= `other`
function gte(StrSlice self, StrSlice other) pure returns (bool) {
    return self.cmp(other) >= 0;
}

/**
 * @dev Checks that `index`-th byte is safe to split on.
 * The start and end of the string (when index == self.len()) are considered to be boundaries.
 * Returns false if index is greater than self.len().
 */
function isCharBoundary(StrSlice self, uint256 index) pure returns (bool) {
    if (index < self.len()) {
        return isValidUtf8(self.asSlice().getAfter(index).copyToBytes32());
    } else if (index == self.len()) {
        return true;
    } else {
        return false;
    }
}

/**
 * @dev Returns the character at `index` (in bytes).
 * Reverts if index is out of bounds.
 */
function get(StrSlice self, uint256 index) pure returns (StrChar char) {
    bytes32 b = self.asSlice().getAfter(index).copyToBytes32();
    if (!isValidUtf8(b)) revert StrSlice__InvalidCharBoundary();
    return StrChar__.fromValidUtf8(b);
}

/**
 * @dev Divides one string slice into two at an index.
 * Reverts when splitting on a non-boundary (use isCharBoundary).
 */
function splitAt(StrSlice self, uint256 mid) pure returns (StrSlice, StrSlice) {
    (Slice lSlice, Slice rSlice) = self.asSlice().splitAt(mid);
    if (!StrSlice__.isBoundaryStart(lSlice) || !StrSlice__.isBoundaryStart(rSlice)) {
        revert StrSlice__InvalidCharBoundary();
    }
    return (
        StrSlice.wrap(Slice.unwrap(lSlice)),
        StrSlice.wrap(Slice.unwrap(rSlice))
    );
}

/**
 * @dev Returns a subslice [start..end) of `self`.
 * Reverts when slicing a non-boundary (use isCharBoundary).
 */
function getSubslice(StrSlice self, uint256 start, uint256 end) pure returns (StrSlice) {
    Slice subslice = self.asSlice().getSubslice(start, end);
    if (!StrSlice__.isBoundaryStart(subslice)) revert StrSlice__InvalidCharBoundary();
    if (end != self.len()) {
        (, Slice nextSubslice) = self.asSlice().splitAt(end);
        if (!StrSlice__.isBoundaryStart(nextSubslice)) revert StrSlice__InvalidCharBoundary();
    }
    return StrSlice.wrap(Slice.unwrap(subslice));
}

/**
 * @dev Returns the byte index of the first slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function find(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().find(pattern.asSlice());
}

/**
 * @dev Returns the byte index of the last slice of `self` that matches `pattern`.
 * Returns type(uint256).max if the `pattern` does not match.
 */
function rfind(StrSlice self, StrSlice pattern) pure returns (uint256) {
    return self.asSlice().rfind(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a sub-slice of this string slice.
 */
function contains(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().contains(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a prefix of this string slice.
 */
function startsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().startsWith(pattern.asSlice());
}

/**
 * @dev Returns true if the given pattern matches a suffix of this string slice.
 */
function endsWith(StrSlice self, StrSlice pattern) pure returns (bool) {
    return self.asSlice().endsWith(pattern.asSlice());
}

/**
 * @dev Returns a subslice with the prefix removed.
 * If it does not start with `prefix`, returns `self` unmodified.
 */
function stripPrefix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripPrefix(pattern.asSlice())
    ));
}

/**
 * @dev Returns a subslice with the suffix removed.
 * If it does not end with `suffix`, returns `self` unmodified.
 */
function stripSuffix(StrSlice self, StrSlice pattern) pure returns (StrSlice result) {
    return StrSlice.wrap(Slice.unwrap(
        self.asSlice().stripSuffix(pattern.asSlice())
    ));
}

/**
 * @dev Replaces first `n` matches of a pattern with another string slice.
 * Returns the result in a newly allocated string.
 * Note this does not modify the string `self` is a slice of.
 * WARNING: Requires 0 < pattern.len() <= to.len()
 */
function replacen(
    StrSlice self,
    StrSlice pattern,
    StrSlice to,
    uint256 n
) view returns (string memory str) {
    // TODO dynamic string; atm length can be reduced but not increased
    assert(pattern.len() >= to.len());
    assert(pattern.len() > 0);

    str = new string(self.len());
    Slice iterSlice = self.asSlice();
    Slice resultSlice = StrSlice__.from(str).asSlice();

    uint256 matchNum;
    while (matchNum < n) {
        uint256 index = iterSlice.find(pattern.asSlice());
        // break if no more matches
        if (index == type(uint256).max) break;
        // copy prefix
        if (index > 0) {
            resultSlice
                .getSubslice(0, index)
                .copyFromSlice(
                    iterSlice.getSubslice(0, index)
                );
        }

        // copy replacement
        // TODO this is fine atm only because pattern.len() <= to.len()
        resultSlice
            .getSubslice(index, index + to.len())
            .copyFromSlice(to.asSlice());

        // advance slices past the match
        iterSlice = iterSlice.getSubslice(index, index + pattern.len());
        resultSlice = iterSlice.getSubslice(index, index + to.len());

        // break if iterSlice is done
        if (iterSlice.len() == 0) {
            break;
        }
    }

    uint256 realLen = resultSlice.ptr() - StrSlice__.from(str).ptr();
    // copy suffix
    if (iterSlice.len() > 0) {
        resultSlice
            .getSubslice(0, iterSlice.len())
            .copyFromSlice(iterSlice);
        realLen += iterSlice.len();
    }
    // remove extra length
    if (bytes(str).length != realLen) {
        assert(realLen <= bytes(str).length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, realLen)
        }
    }
    return str;
}

/**
 * @dev Returns an character iterator over the slice.
 * The iterator yields items from either side.
 */
function chars(StrSlice self) pure returns (StrCharsIter memory) {
    return StrCharsIter__.from(self);
}