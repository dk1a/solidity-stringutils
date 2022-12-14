# StrSlice & Slice library for Solidity

- Types: [StrSlice](src/StrSlice.sol) for strings, [Slice](src/Slice.sol) for bytes, [StrChar](src/StrChar.sol) for characters
- [Gas efficient](https://github.com/dk1a/solidity-stringutils-gas)
- Versioned releases, available for both foundry and hardhat
- Simple imports, you only need e.g. `StrSlice` and `toSlice`
- `StrSlice` enforces UTF-8 character boundaries; `StrChar` validates character encoding
- Clean, well-documented and thoroughly-tested source code
- Optional [PRBTest](https://github.com/paulrberg/prb-test) extension with assertions like `assertContains` and `assertLt` for both slices and native `bytes`, `string`
- `Slice` and `StrSlice` are value types, not structs
- Low-level functions like [memchr](src/utils/memchr.sol), [memcmp, memmove etc](src/utils/mem.sol)

## Install

### Node
```sh
yarn add @dk1a/solidity-stringutils
```

### Forge
```sh
forge install --no-commit dk1a/solidity-stringutils
```

## StrSlice

```solidity
import { StrSlice, toSlice } from "@dk1a/solidity-stringutils/src/StrSlice.sol";

using { toSlice } for string;

/// @dev Returns the content of brackets, or empty string if not found
function extractFromBrackets(string memory stuffInBrackets) pure returns (StrSlice extracted) {
    StrSlice s = stuffInBrackets.toSlice();
    bool found;

    (found, , s) = s.splitOnce(toSlice("("));
    if (!found) return toSlice("");

    (found, s, ) = s.rsplitOnce(toSlice(")"));
    if (!found) return toSlice("");

    return s;
}
/*
assertEq(
    extractFromBrackets("((1 + 2) + 3) + 4"),
    toSlice("(1 + 2) + 3")
);
*/
```

See [ExamplesTest](test/Examples.t.sol).

Internally `StrSlice` uses `Slice` and extends it with logic for multibyte UTF-8 where necessary.

| Method           | Description                                      |
| ---------------- | ------------------------------------------------ |
| `len`            | length in **bytes**                              |
| `isEmpty`        | true if len == 0                                 |
| `toString`       | copy slice contents to a **new** string          |
| `keccak`         | equal to `keccak256(s.toString())`, but cheaper  |
**concatenate**
| `add`            | Concatenate 2 slices into a **new** string       |
| `join`           | Join slice array on `self` as separator          |
**compare**
| `cmp`            | 0 for eq, < 0 for lt, > 0 for gt                 |
| `eq`,`ne`        | ==, !=  (more efficient than cmp)                |
| `lt`,`lte`       | <, <=                                            |
| `gt`,`gte`       | >, >=                                            |
**index**
| `isCharBoundary` | true if given index is an allowed boundary       |
| `get`            | get 1 UTF-8 character at given index             |
| `splitAt`        | (slice[:index], slice[index:])                   |
| `getSubslice`    | slice[start:end]                                 |
**search**
| `find`           | index of the start of the **first** match        |
| `rfind`          | index of the start of the **last** match         |
|                  | *return `type(uint256).max` for no matches*      |
| `contains`       | true if a match is found                         |
| `startsWith`     | true if starts with pattern                      |
| `endsWith`       | true if ends with pattern                        |
**modify**
| `stripPrefix`    | returns subslice without the prefix              |
| `stripSuffix`    | returns subslice without the suffix              |
| `splitOnce`      | split into 2 subslices on the **first** match    |
| `rsplitOnce`     | split into 2 subslices on the **last** match     |
| `replacen`       | *experimental* replace `n` matches               |
|                  | *replacen requires 0 < pattern.len() <= to.len()*|
**iterate**
| `chars`          | character iterator over the slice                |
**ascii**
| `isAscii`        | true if all chars are ASCII                      |
**dangerous**
| `asSlice`        | get underlying Slice                             |
| `ptr`            | get memory pointer                               |

Indexes are in **bytes**, not characters. Indexing methods revert if `isCharBoundary` is false.

## StrCharsIter

*Returned by `chars` method of `StrSlice`*

```solidity
import { StrSlice, toSlice, StrCharsIter } from "@dk1a/solidity-stringutils/src/StrSlice.sol";

using { toSlice } for string;

/// @dev Returns a StrSlice of `str` with the 2 first UTF-8 characters removed
/// reverts on invalid UTF8
function removeFirstTwoChars(string memory str) pure returns (StrSlice) {
    StrCharsIter memory chars = str.toSlice().chars();
    for (uint256 i; i < 2; i++) {
        if (chars.isEmpty()) break;
        chars.next();
    }
    return chars.asStr();
}
/*
assertEq(removeFirstTwoChars(unicode"📎!こんにちは"), unicode"こんにちは");
*/
```

| Method           | Description                                      |
| ---------------- | ------------------------------------------------ |
| `asStr`          | get underlying StrSlice of the remainder         |
| `len`            | remainder length in **bytes**                    |
| `isEmpty`        | true if len == 0                                 |
| `next`           | advance the iterator, return the next StrChar    |
| `nextBack`       | advance from the back, return the next StrChar   |
| `count`          | returns the number of UTF-8 characters           |
| `validateUtf8`   | returns true if the sequence is valid UTF-8      |
**dangerous**
| `unsafeNext`     | advance unsafely, return the next StrChar        |
| `unsafeCount`    | unsafely count chars, read the source for caveats|
| `ptr`            | get memory pointer                               |

`count`, `validateUtf8`, `unsafeCount` consume the iterator in O(n).

Safe methods revert on an invalid UTF-8 byte sequence.

`unsafeNext` does NOT check if the iterator is empty, may underflow! Does not revert on invalid UTF-8. If returned `StrChar` is invalid, it will have length 0. Otherwise length 1-4.

Internally `next`, `unsafeNext`, `count` all use `_nextRaw`. It's very efficient, but very unsafe and complicated. Read the source and import it separately if you need it.

## StrChar

Represents a single UTF-8 encoded character.
Internally it's bytes32 with leading byte at MSB.

It's returned by some methods of `StrSlice` and `StrCharsIter`.

| Method           | Description                                      |
| ---------------- | ------------------------------------------------ |
| `len`            | character length in bytes                        |
| `toBytes32`      | returns the underlying `bytes32` value           |
| `toString`       | copy the character to a new string               |
| `toCodePoint`    | returns the unicode code point (`ord` in python) |
| `cmp`            | 0 for eq, < 0 for lt, > 0 for gt                 |
| `eq`,`ne`        | ==, !=                                           |
| `lt`,`lte`       | <, <=                                            |
| `gt`,`gte`       | >, >=                                            |
| `isValidUtf8`    | usually true                                     |
| `isAscii`        | true if the char is ASCII                        |

Import `StrChar__` (static function lib) to use `StrChar__.fromCodePoint` for code point to `StrChar` conversion.

`len` can return `0` *only* for invalid UTF-8 characters. But some invalid chars *may* have non-zero len! (use `isValidUtf8` to check validity). Note that `0x00` is a valid 1-byte UTF-8 character, its len is 1.

`isValidUtf8` can be false if the character was formed with an unsafe method (fromUnchecked, wrap).

## Slice

```solidity
import { Slice, toSlice } from "@dk1a/solidity-stringutils/src/Slice.sol";

using { toSlice } for bytes;

function findZeroByte(bytes memory b) pure returns (uint256 index) {
    return b.toSlice().find(
        bytes(hex"00").toSlice()
    );
}
```

See `using {...} for Slice global` in the source for a function summary. Many are shared between `Slice` and `StrSlice`, but there are differences.

Internally Slice has very minimal assembly, instead using `memcpy`, `memchr`, `memcmp` and others; if you need the low-level functions, see `src/utils/`.

## Assertions (PRBTest extension)

```solidity
import { PRBTest } from "@prb/test/src/PRBTest.sol";
import { Assertions } from "@dk1a/solidity-stringutils/src/test/Assertions.sol";

contract StrSliceTest is PRBTest, Assertions {
    function testContains() public {
        bytes memory b1 = "12345";
        bytes memory b2 = "3";
        assertContains(b1, b2);
    }

    function testLt() public {
        string memory s1 = "123";
        string memory s2 = "124";
        assertLt(s1, s2);
    }
}
```

You can completely ignore slices if all you want is e.g. `assertContains` for native `bytes`/`string`.

## Acknowledgements
- [Arachnid/solidity-stringutils](https://github.com/Arachnid/solidity-stringutils) - I basically wanted to make an updated version of solidity-stringutils
- [rust](https://doc.rust-lang.org/core/index.html) - most similarities are in names and general structure; the implementation can't really be similar (solidity doesn't even have generics)
- [paulrberg/prb-math](https://github.com/paulrberg/prb-math) - good template for solidity data structure libraries with `using {...} for ... global`
- [brockelmore/memmove](https://github.com/brockelmore/memmove) - good assembly memory management examples