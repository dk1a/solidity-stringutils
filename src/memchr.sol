// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 *
 * Loosely based on https://doc.rust-lang.org/1.65.0/core/slice/memchr/
 */

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256 index) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memchrWord(ptrText, lenText, x);
    }

    uint256 offset;
    uint256 repeatedX = repeatByte(x);
    while (lenText >= 32) {
        uint256 chunk;
        /// @solidity memory-safe-assembly
        assembly {
            chunk := mload(ptrText)
        }
        // break if there is a matching byte
        if (containsZeroByte(chunk ^ repeatedX)) {
            break;
        }

        ptrText += 32;
        lenText -= 32;
        offset += 32;
    }

    if (lenText == 0) return type(uint256).max;

    index = memchrWord(ptrText, lenText, x);
    if (index == type(uint256).max) {
        return type(uint256).max;
    } else {
        return index + offset;
    }
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 */
function memrchr(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText <= 32) {
        // Fast path for small slices.
        return memrchrWord(ptrText, lenText, x);
    }

    uint256 offsetPtr;
    // safe because pointers are guaranteed to be valid by the caller
    unchecked {
        offsetPtr = ptrText + lenText;
    }

    // Check the unaligned tail, if it exists.
    uint256 lenTail = lenText % 32;
    if (lenTail != 0) {
        // remove tail length
        // - is safe because lenTail <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= lenTail;
        }
        // return if there is a matching byte
        uint256 index = memrchrWord(offsetPtr, lenTail, x);
        if (index != type(uint256).max) {
            return index + (offsetPtr - ptrText);
        }
    }

    uint256 repeatedX = repeatByte(x);
    while (offsetPtr > ptrText) {
        // - is safe because 32 <= lenText <= offsetPtr
        unchecked {
            offsetPtr -= 32;
        }

        uint256 chunk;
        /// @solidity memory-safe-assembly
        assembly {
            chunk := mload(offsetPtr)
        }
        // break if there is a matching byte
        if (containsZeroByte(chunk ^ repeatedX)) {
            uint256 index = memrchrWord(offsetPtr, 32, x);
            return index + (offsetPtr - ptrText);
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the first index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memchr after its chunk search.
 */
function memchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText > 32) {
        lenText = 32;
    }
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }
    // ++ is safe because lenText <= 32
    unchecked {
        for (uint256 i; i < lenText; i++) {
            uint8 b;
            assembly {
                b := byte(i, chunk)
            }
            if (b == x) return i;
        }
    }
    // not found
    return type(uint256).max;
}

/**
 * @dev Returns the last index matching the byte `x` in text;
 * or type(uint256).max if not found.
 * 
 * WARNING: it works ONLY for length 32 or less.
 * This is for use by memrchr after its chunk search.
 */
function memrchrWord(uint256 ptrText, uint256 lenText, uint8 x) pure returns (uint256) {
    if (lenText > 32) {
        lenText = 32;
    }
    uint256 chunk;
    /// @solidity memory-safe-assembly
    assembly {
        chunk := mload(ptrText)
    }
    while (lenText > 0) {
        // -- is safe because lenText > 0
        unchecked {
            lenText--;
        }
        uint8 b;
        assembly {
            b := byte(lenText, chunk)
        }
        if (b == x) return lenText;
    }
    // not found
    return type(uint256).max;
}

/// @dev repeating low bit for containsZeroByte
uint256 constant LO_U256 = 0x0101010101010101010101010101010101010101010101010101010101010101;
/// @dev repeating high bit for containsZeroByte
uint256 constant HI_U256 = 0x8080808080808080808080808080808080808080808080808080808080808080;

/**
 * @dev Returns `true` if `x` contains any zero byte.
 *
 * From *Matters Computational*, J. Arndt:
 *
 * "The idea is to subtract one from each of the bytes and then look for
 * bytes where the borrow propagated all the way to the most significant bit."
 */
function containsZeroByte(uint256 x) pure returns (bool) {
    unchecked {
        return (x - LO_U256) & (~x) & HI_U256 != 0;
    }
    /*
     * An example of how it works:
     *                                              here is 00
     * x    0x0101010101010101010101010101010101010101010101000101010101010101
     * x-LO 0xffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000
     * ~x   0xfefefefefefefefefefefefefefefefefefefefefefefefffefefefefefefefe
     * &1   0xfefefefefefefefefefefefefefefefefefefefefefefeff0000000000000000
     * &2   0x8080808080808080808080808080808080808080808080800000000000000000
     */
}

/// @dev Repeat byte `b` 32 times
function repeatByte(uint8 b) pure returns (uint256) {
    // e.g. 0x5A * 0x010101..010101 = 0x5A5A5A..5A5A5A
    return b * (type(uint256).max / type(uint8).max);
}