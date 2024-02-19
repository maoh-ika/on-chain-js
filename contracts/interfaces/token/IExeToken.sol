// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interpreter/IJSInterpreter.sol';

interface IExeToken {
  function execute(uint tokenId, IJSInterpreter.JSValue[] memory args) external view returns (IJSInterpreter.JSValue memory);
}