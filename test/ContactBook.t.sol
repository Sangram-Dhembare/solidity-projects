// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { ContactBook } from "../src/ContactBook.sol";

contract ContactBookTest is Test {
    ContactBook private book;

    function setUp() public {
        book = new ContactBook();
    }

    function testAddContactAndEmitEvent() public {
        address contact = address(0xA11CE);
        vm.expectEmit(true, true, false, false);
        emit ContactBook.ContactAdded(address(this), contact);

        book.addContact(contact);

        assertTrue(book.isContact(contact));
        assertEq(book.contactCount(), 1);
        assertEq(book.contactAt(0), contact);
    }

    function testRemoveContactAndEmitEvent() public {
        address first = address(0xA11CE);
        address second = address(0xBEEF);
        book.addContact(first);
        book.addContact(second);
        vm.expectEmit(true, true, false, false);
        emit ContactBook.ContactRemoved(address(this), first);

        book.removeContact(first);

        assertFalse(book.isContact(first));
        assertTrue(book.isContact(second));
        assertEq(book.contactCount(), 1);
        assertEq(book.contactAt(0), second);
    }

    function testRejectsZeroAndSelfAddresses() public {
        vm.expectRevert(abi.encodeWithSelector(ContactBook.InvalidContact.selector, address(0)));
        book.addContact(address(0));
        vm.expectRevert(abi.encodeWithSelector(ContactBook.InvalidContact.selector, address(this)));
        book.addContact(address(this));
    }

    function testRejectsDuplicateContact() public {
        address contact = address(0xA11CE);
        book.addContact(contact);

        vm.expectRevert(abi.encodeWithSelector(ContactBook.AlreadyContact.selector, contact));
        book.addContact(contact);
    }

    function testRejectsRemovingUnknownContact() public {
        address contact = address(0xA11CE);

        vm.expectRevert(abi.encodeWithSelector(ContactBook.ContactNotFound.selector, contact));
        book.removeContact(contact);
    }

    function testContactListsArePerCaller() public {
        address contact = address(0xA11CE);
        address other = address(0xBEEF);
        book.addContact(contact);

        vm.prank(other);
        assertFalse(book.isContact(contact));
        vm.prank(other);
        assertEq(book.contactCount(), 0);
    }

    function testContactAtRejectsOutOfBoundsIndex() public {
        vm.expectRevert(abi.encodeWithSelector(ContactBook.ContactIndexOutOfBounds.selector, 0, 0));
        book.contactAt(0);
    }
}
