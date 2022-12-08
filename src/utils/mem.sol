// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * These functions are VERY DANGEROUS!
 * They operate directly on memory pointers, use with caution.
 *
 * Assembly here is marked as memory-safe for optimization.
 * The caller MUST use pointers in a memory-safe way!
 * https://docs.soliditylang.org/en/latest/assembly.html#memory-safety
 */

/**
 * @dev Load 1 byte from the pointer.
 * The result is in the least significant byte, hence uint8.
 */
function mload8(uint256 ptr) pure returns (uint8 item) {
    /// @solidity memory-safe-assembly
    assembly {
        item := byte(0, mload(ptr))
    }
    return item;
}

/**
 * @dev Copy `n` memory bytes.
 * WARNING: Does not handle pointer overlap!
 */
function memcpy(uint256 ptrDest, uint256 ptrSrc, uint256 length) pure {
    // Copy word-length chunks while possible
    for(; length >= 32; length -= 32) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(ptrDest, mload(ptrSrc))
        }
        ptrDest += 32;
        ptrSrc += 32;
    }
    if (length == 0) return;

    // Copy remaining bytes
    bytes32 data;
    /// @solidity memory-safe-assembly
    assembly {
        data := mload(ptrSrc)
    }
    mstoreN(ptrDest, data, length);
}

/**
 * @dev mstore `n` bytes (left-aligned) of `data`
 */
function mstoreN(uint256 ptrDest, bytes32 data, uint256 n) pure {
    uint256 mask = leftMask(n);
    /// @solidity memory-safe-assembly
    assembly {
        mstore(ptrDest,
            or(
                // store the left part
                and(data, mask),
                // preserve the right part
                and(mload(ptrDest), not(mask))
            )
        )
    }
}

/**
 * @dev Copy `n` memory bytes using identity precompile.
 */
function memmove(uint256 ptrDest, uint256 ptrSrc, uint256 n) view {
    /// @solidity memory-safe-assembly
    assembly {
        pop(
            staticcall(
                gas(),   // gas (unused is returned)
                0x04,    // identity precompile address
                ptrSrc,  // argsOffset
                n,       // argsSize: byte size to copy
                ptrDest, // retOffset
                n        // retSize: byte size to copy
            )
        )
    }
}

/**
 * @dev Compare `n` memory bytes lexicographically.
 * Returns 0 for equal, < 0 for less than and > 0 for greater than.
 *
 * https://doc.rust-lang.org/std/cmp/trait.Ord.html#lexicographical-comparison
 */
function memcmp(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (int256) {
    while (n >= 32) {
        uint256 chunkSelf;
        uint256 chunkOther;
        /// @solidity memory-safe-assembly
        assembly {
            chunkSelf := mload(ptrSelf)
            chunkOther := mload(ptrOther)
        }

        if (chunkSelf < chunkOther) {
            return -1;
        } else if (chunkSelf > chunkOther) {
            return 1;
        }

        n -= 32;
        ptrSelf += 32;
        ptrOther += 32;
    }

    if (n == 0) return 0;

    uint256 mask = leftMask(n);
    int256 diff;
    /// @solidity memory-safe-assembly
    assembly {
        // for <32 bytes subtraction can be used for comparison,
        // just need to shift away from MSB
        diff := sub(
            shr(8, and(mload(ptrSelf), mask)),
            shr(8, and(mload(ptrOther), mask))
        )
    }
    return diff;
}

/**
 * @dev Returns true if `n` memory bytes are equal.
 *
 * It's much faster than memcmp, you may want to use them together.
 * bytes ~diff
 * 1     3x
 * 32    4.5x
 * 33    5.5x
 * 100   10x
 * 3000  26x
 * TODO binary search in memcmp with memeq for big sequences
 */
function memeq(uint256 ptrSelf, uint256 ptrOther, uint256 n) pure returns (bool result) {
    /// @solidity memory-safe-assembly
    assembly {
        result := eq(keccak256(ptrSelf, n), keccak256(ptrOther, n))
    }
}

/**
 * @dev Left-aligned byte mask for partial mload/mstore
 *
 * length 0:  0x000000...000000
 * length 1:  0xff0000...000000
 * length 2:  0xffff00...000000
 * ...
 * length 30: 0xffffff...ff0000
 * length 31: 0xffffff...ffff00
 * length 32: 0xffffff...ffffff
 */
function leftMask(uint256 length) pure returns (uint256) {
    assert(length <= 32);

    unchecked {
        return ~((1 << (8 * (32 - length))) - 1);
    }
}