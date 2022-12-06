// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Returns the byte length for a UTF-8 character with the leading byte.
 * Returns 0 for invalid leading bytes.
 */
function utf8CharWidth(uint8 leadingByte) pure returns (uint256) {
    if (leadingByte < 0x80) {
        return 1;
    } else if (leadingByte < 0xC2) {
        return 0;
    } else if (leadingByte < 0xE0) {
        return 2;
    } else if (leadingByte < 0xF0) {
        return 3;
    } else if (leadingByte < 0xF5) {
        return 4;
    } else {
        return 0;
    }
}

/**
 * @dev Returns true if `b` is a valid UTF-8 leading byte.
 */
function isLeadingByte(uint8 b) pure returns (bool) {
    return utf8CharWidth(b) > 0;
}

/**
 * @dev Returns true if the 1-4 bytes at MSB are a valid UTF-8 encoded character.
 * Note if MSB is 0x00, this will return true, since 0x00 is valid UTF-8.
 * Works faster for smaller code points.
 *
 * https://www.rfc-editor.org/rfc/rfc3629#section-4
 * UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
 * UTF8-1      = %x00-7F
 * UTF8-2      = %xC2-DF UTF8-tail
 * UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
 *               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
 * UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
 *               %xF4 %x80-8F 2( UTF8-tail )
 * UTF8-tail   = %x80-BF
 */
function isValidUtf8(bytes32 b) pure returns (bool) {
    // TODO you can significantly optimize comparisons with bitmasks,
    // some stuff to look at:
    // https://github.com/zwegner/faster-utf8-validator/blob/master/z_validate.c
    // https://github.com/websockets/utf-8-validate/blob/master/src/validation.c
    // https://github.com/simdutf/simdutf/blob/master/src/scalar/utf8.h

    uint8 first = uint8(b[0]);
    // UTF8-1 = %x00-7F
    if (first <= 0x7F) {
        // fast path for ascii
        return true;
    }

    uint256 w = utf8CharWidth(first);
    if (w == 2) {
        // UTF8-2
        return
            // %xC2-DF UTF8-tail
            _bRange(first, 0xC2, 0xDF)
            && _utf8Tail(uint8(b[1]));
    } else if (w == 3) {
        uint8 second = uint8(b[1]);
        // UTF8-3
        bool valid12 =
            // = %xE0 %xA0-BF UTF8-tail
            first == 0xE0
            && _bRange(second, 0xA0, 0xBF)
            // / %xE1-EC 2( UTF8-tail )
            || _bRange(first, 0xE1, 0xEC)
            && _utf8Tail(second)
            // / %xED %x80-9F UTF8-tail
            || first == 0xED
            && _bRange(second, 0x80, 0x9F)
            // / %xEE-EF 2( UTF8-tail )
            || _bRange(first, 0xEE, 0xEF)
            && _utf8Tail(second);

        return valid12 && _utf8Tail(uint8(b[2]));
    } else if (w == 4) {
        uint8 second = uint8(b[1]);
        // UTF8-4
        bool valid12 =
            // = %xF0 %x90-BF 2( UTF8-tail )
            first == 0xF0
            && _bRange(second, 0x90, 0xBF)
            // / %xF1-F3 3( UTF8-tail )
            || _bRange(first, 0xF1, 0xF3)
            && _utf8Tail(second)
            // / %xF4 %x80-8F 2( UTF8-tail )
            || first == 0xF4
            && _bRange(second, 0x80, 0x8F);

        return valid12 && _utf8Tail(uint8(b[2])) && _utf8Tail(uint8(b[3]));
    } else {
        return false;
    }
}

/// @dev left <= b <= right
function _bRange(uint8 b, uint8 left, uint8 right) pure returns (bool) {
    return left <= b && b <= right;
}

/// @dev UTF8-tail = %x80-BF
function _utf8Tail(uint8 b) pure returns (bool) {
    // and,cmp should be faster than cmp,cmp,and
    // 0xC0 = 0b1100_0000, 0x80 = 0b1000_0000
    return b & 0xC0 == 0x80;
}