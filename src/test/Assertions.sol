// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { SliceAssertions } from "./SliceAssertions.sol";
import { StrSliceAssertions } from "./StrSliceAssertions.sol";

/// @title Extension to PRBTest with Slice and StrSlice assertions.
/// @dev Also provides lt,lte,gt,gte,contains for 2 native `bytes` and 2 native `string`.
contract Assertions is SliceAssertions, StrSliceAssertions {
}