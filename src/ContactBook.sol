// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ContactBook
/// @notice Lets each address maintain a public list of wallet contacts.
contract ContactBook {
    mapping(address owner => address[] contacts) private contacts;
    mapping(address owner => mapping(address contact => uint256 indexPlusOne)) private
        contactIndexes;

    event ContactAdded(address indexed owner, address indexed contact);
    event ContactRemoved(address indexed owner, address indexed contact);

    error InvalidContact(address contact);
    error AlreadyContact(address contact);
    error ContactNotFound(address contact);
    error ContactIndexOutOfBounds(uint256 index, uint256 count);

    /// @notice Adds a wallet address to the caller's contact list.
    /// @param contact The wallet address to add.
    function addContact(
        address contact
    ) external {
        if (contact == address(0) || contact == msg.sender) revert InvalidContact(contact);
        if (contactIndexes[msg.sender][contact] != 0) revert AlreadyContact(contact);

        contacts[msg.sender].push(contact);
        contactIndexes[msg.sender][contact] = contacts[msg.sender].length;
        emit ContactAdded(msg.sender, contact);
    }

    /// @notice Removes a wallet address from the caller's contact list.
    /// @param contact The wallet address to remove.
    function removeContact(
        address contact
    ) external {
        uint256 indexPlusOne = contactIndexes[msg.sender][contact];
        if (indexPlusOne == 0) revert ContactNotFound(contact);

        address[] storage ownerContacts = contacts[msg.sender];
        uint256 index = indexPlusOne - 1;
        uint256 lastIndex = ownerContacts.length - 1;
        if (index != lastIndex) {
            address lastContact = ownerContacts[lastIndex];
            ownerContacts[index] = lastContact;
            contactIndexes[msg.sender][lastContact] = indexPlusOne;
        }

        ownerContacts.pop();
        delete contactIndexes[msg.sender][contact];
        emit ContactRemoved(msg.sender, contact);
    }

    /// @notice Checks whether an address is in the caller's contact list.
    function isContact(
        address contact
    ) external view returns (bool) {
        return contactIndexes[msg.sender][contact] != 0;
    }

    /// @notice Returns the number of contacts in the caller's list.
    function contactCount() external view returns (uint256) {
        return contacts[msg.sender].length;
    }

    /// @notice Returns a contact by its current zero-based list index.
    function contactAt(
        uint256 index
    ) external view returns (address) {
        address[] storage ownerContacts = contacts[msg.sender];
        if (index >= ownerContacts.length) {
            revert ContactIndexOutOfBounds(index, ownerContacts.length);
        }
        return ownerContacts[index];
    }
}
