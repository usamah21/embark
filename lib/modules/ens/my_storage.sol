pragma solidity ^0.4.17;

contract MyStorage {
  uint public storedData;

  function() public payable { }

  function MyStorage(uint initialValue) public {
    storedData = initialValue;
  }

}

