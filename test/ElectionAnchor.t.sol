// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ElectionAnchor } from "../src/ElectionAnchor.sol";

contract ElectionAnchorTest is Test {
    ElectionAnchor private anchor;
    bytes32 private constant APP_CONFIG_DIGEST =
        0x821605bdc7ae3cbfa16600c5d9a6e1c00d6f6cc90cec43614bd809f0ecadf48e;

    function setUp() public {
        anchor = new ElectionAnchor();
    }

    function testAnchorsAppConfigDigestAndEmitsEvent() public {
        address organizer = address(0xA11CE);
        vm.warp(1_800_000_000);

        vm.expectEmit(true, true, false, true, address(anchor));
        emit ElectionAnchor.ConfigAnchored(APP_CONFIG_DIGEST, organizer, block.timestamp);
        vm.prank(organizer);
        anchor.anchor(APP_CONFIG_DIGEST);

        assertTrue(anchor.verify(APP_CONFIG_DIGEST));
        assertTrue(anchor.isAnchored(APP_CONFIG_DIGEST));
        assertEq(anchor.organizerOf(APP_CONFIG_DIGEST), organizer);
        assertEq(anchor.anchoredAt(APP_CONFIG_DIGEST), block.timestamp);
    }

    function testVerifyReturnsFalseForUnknownDigest() public view {
        assertFalse(anchor.verify(bytes32(uint256(1))));
    }

    function testRejectsZeroDigest() public {
        vm.expectRevert(ElectionAnchor.ZeroDigest.selector);
        anchor.anchor(bytes32(0));
    }

    function testRejectsDuplicateDigest() public {
        anchor.anchor(APP_CONFIG_DIGEST);

        vm.expectRevert(
            abi.encodeWithSelector(ElectionAnchor.DigestAlreadyAnchored.selector, APP_CONFIG_DIGEST)
        );
        anchor.anchor(APP_CONFIG_DIGEST);
    }
}
