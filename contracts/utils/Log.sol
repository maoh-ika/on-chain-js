// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import '../lexer/TokenAttrsUtil.sol';
import '../ast/AstNodeValueUtil.sol';
import '../interfaces/utf8/IUtf8Char.sol';
import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interpreter/JSValueUtil.sol';
import '../interpreter/JSArrayImpl.sol';
import '../interpreter/JSObjectImpl.sol';
import '../interpreter/StringUtil.sol';

library JSArrayElementUtilLog {
  function numberValue(IJSInterpreter.JSArrayElement memory value) internal pure returns (uint) {
    if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      return abi.decode(value.value, (uint));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      bool bl = abi.decode(value.value, (bool));
      return bl ? JSValueUtil.toWei(1) : 0;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (uint num,) = abi.decode(value.value, (uint, string));
      return num;
    } else {
      return 0;
    }
  }
  
  function boolValue(IJSInterpreter.JSArrayElement memory value) internal pure returns (bool) {
    if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      return abi.decode(value.value, (uint)) != 0;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      return abi.decode(value.value, (bool));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (uint num, string memory str) = abi.decode(value.value, (uint, string));
      return num != 0 && !StringUtil.equal(str, '');
    } else if (value.valueType == IJSInterpreter.JSValueType.value_string) {
      (string memory str) = abi.decode(value.value, (string));
      return !StringUtil.equal(str, '');
    } else {
      return false;
    }
  }
  
  function stringValue(IJSInterpreter.JSArrayElement memory value) internal pure returns (string memory) {
    if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (,string memory str) = abi.decode(value.value, (uint, string));
      return str;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_string) {
      return  abi.decode(value.value, (string));
    } else {
      return '';
    }
  }
}

library JSObjectPropertyUtilLog {
  function numberValue(IJSInterpreter.JSObjectProperty memory value) internal pure returns (uint) {
    if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      return abi.decode(value.value, (uint));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      bool bl = abi.decode(value.value, (bool));
      return bl ? JSValueUtil.toWei(1) : 0;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (uint num,) = abi.decode(value.value, (uint, string));
      return num;
    } else {
      return 0;
    }
  }
  
  function boolValue(IJSInterpreter.JSObjectProperty memory value) internal pure returns (bool) {
    if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      return abi.decode(value.value, (uint)) != 0;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      return abi.decode(value.value, (bool));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (uint num, string memory str) = abi.decode(value.value, (uint, string));
      return num != 0 && !StringUtil.equal(str, '');
    } else if (value.valueType == IJSInterpreter.JSValueType.value_string) {
      (string memory str) = abi.decode(value.value, (string));
      return !StringUtil.equal(str, '');
    } else {
      return false;
    }
  }
  
  function stringValue(IJSInterpreter.JSObjectProperty memory value) internal pure returns (string memory) {
    if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (,string memory str) = abi.decode(value.value, (uint, string));
      return str;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_string) {
      return  abi.decode(value.value, (string));
    } else {
      return '';
    }
  }
}

library Log {
  using TokenAttrsUtil for IJSLexer.TokenAttrs;
  using AstNodeValueUtil for IAstBuilder.AstNode;
  using JSValueUtil for IJSInterpreter.JSValue;
  using JSArrayElementUtil for IJSInterpreter.JSArrayElement;
  using JSObjectPropertyUtil for IJSInterpreter.JSObjectProperty;
  using JSArrayElementUtilLog for IJSInterpreter.JSArrayElement;
  using JSObjectPropertyUtilLog for IJSInterpreter.JSObjectProperty;

  function log(string memory str) public view {
    console.log(str);
  }
  
  function log(string memory str, uint num) public view {
    console.log(str, num);
  }
  
  function log(string memory str, string memory str2) public view {
    console.log(str, str2);
  }
  
  function log(string memory str, uint num, string memory str2) public view {
    console.log(str, num, str2);
  }

  function logChar(IUtf8Char.Utf8Char memory char) public view {
    console.log('char: %s, %d', char.expression, char.code);
  }

  function logToken(IJSLexer.Token memory token) public view {
    console.log('[Token]');
    string memory expression;
    string memory value;
    uint integer;
    uint decimal;
    uint decimalDigits;
    uint exponent;
    bool sign;
    bool expSign;
    if (token.attrs.tokenType == IJSLexer.TokenType.keyword) {
      console.log('  tokenType: keyword');
      expression = token.attrs.decodeKeywordValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.punctuation) {
      console.log('  tokenType: punctuation');
      expression = token.attrs.decodePunctuationValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.operator) {
      console.log('  tokenType: operator');
      expression = token.attrs.decodeOperatorValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.identifier) {
      console.log('  tokenType: identifier');
      (value, expression) = token.attrs.decodeIdentifierValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.number) {
      console.log('  tokenType: number');
      (integer, decimal, decimalDigits, exponent, sign, expSign, expression) = token.attrs.decodeNumberValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.bigInt) {
      console.log('  tokenType: bigInt');
      (integer, decimal, decimalDigits, exponent, sign, expSign, expression) = token.attrs.decodeNumberValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.str) {
      console.log('  tokenType: str');
      (value, expression) = token.attrs.decodeStringValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.numberStr) {
      console.log('  tokenType: numberStr');
      (integer, decimal, decimalDigits, exponent, sign, expSign, value, expression) = token.attrs.decodeNumberStringValue();
    } else if (token.attrs.tokenType == IJSLexer.TokenType.regex) {
      console.log('  tokenType: regex');
      string memory regex;
      string memory regexFlags;
      (regex, regexFlags, expression) = token.attrs.decodeRegexValue();
      console.log('  regexPattern: %s', regex);
      console.log('  regexFlags: %s', regexFlags);
    } else if (token.attrs.tokenType == IJSLexer.TokenType.comment) {
      console.log('  tokenType: comment');
      (value) = token.attrs.decodeCommentValue();
    }
    console.log('  expression: %s', expression);
    console.log('  value: %s', value);
    console.log('  integer: %d', integer);
    console.log('  decimal: %d', decimal);
    console.log('  decimalDigits: %d', decimalDigits);
    console.log('  exponent: %d', exponent);
    console.log('  sign: %s', sign);
    console.log('  expSign: %s', expSign);
    console.log('  tokenCode: %d', token.attrs.tokenCode);
    console.log('  size: %d', token.attrs.size);
    console.log('  startPos: %d', token.startPos);
    console.log('  endPos: %d', token.endPos);
    console.log('  line: %d', token.line);
  }

  function logAstNode(IAstBuilder.AstNode memory node) public view {
    console.log('[Node]');
    console.log('  nodeId: %d', node.nodeId);
    console.log('  nodeType: %s', _toString(node.nodeType));
    console.log('  nodeDescriptor: %d', node.nodeDescriptor);
    console.log('  nodeArray:');
    for (uint i = 0; i < node.nodeArray.length; ++i) {
      console.log('    %d', node.nodeArray[i]);
    }
    if (node.nodeType == IAstBuilder.NodeType.identifier) {
      console.log('  stringValue: %s', node.decodeLiteralString());
    } else if (node.nodeType == IAstBuilder.NodeType.literal) {
      if (node.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_string)) {
        console.log('  stringValue: %s', node.decodeLiteralString());
      } else if (node.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_numberString)) {
        (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign, string memory value) = node.decodeLiteralNumberString();
        console.log('  integer: %d', integer);
        console.log('  decimal: %d', decimal);
        console.log('  decimalDigits: %d', decimalDigits);
        console.log('  exponent: %d', exponent);
        console.log('  sign: %s', sign);
        console.log('  expSign: %s',expSign);
        console.log('  stringValue: %s', value);
      } else if (node.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_number)) {
        (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign) = node.decodeLiteralNumber();
        console.log('  integer: %d', integer);
        console.log('  decimal: %d', decimal);
        console.log('  decimalDigits: %d', decimalDigits);
        console.log('  exponent: %d', exponent);
        console.log('  sign: %s', sign);
        console.log('  expSign: %s',expSign);
      } else if (node.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_boolean)) {
        console.log('  boolValue: %s', node.decodeLiteralBoolean());
      } else if (node.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_regex)) {
        (string memory pattern, string memory flags) = node.decodeLiteralRegex();
        console.log('  pattern: %s', pattern);
        console.log('  flags: %s', flags);
      }
    }
  }

  function logJSValue(IJSInterpreter.JSValue memory value) public view {
    console.log('[JSValue]');
    console.log('  valueType: %s', _toString(value.valueType));
    console.log('  identifierIndex: %d', value.identifierIndex);
    console.log('  numberValue: %d', value.numberValue());
    console.log('  stringValue: %s', value.stringValue());
    console.log('  numberSign: %s', _toString(value.numberSign));
    console.log('  boolValue: %s', _toString(value.boolValue()));
    console.log('    size: %d', value.value.length);
    console.log('  arrayValue: ');
    console.log('    size: %d', value.arrayValue().elements.length);
    console.log('    rootElementIndex: %d', value.arrayValue().rootElementIndex);
    for (uint i = 0; i < value.arrayValue().elements.length; ++i) {
      logArrayElement(value.arrayValue().elements[i], i);
    }
    console.log('  objectrValue: ');
    console.log('    size: %d', value.objectValue().properties.length);
    console.log('    rootPropertyIndex: %d', value.objectValue().rootPropertyIndex);
    for (uint i = 0; i < value.objectValue().properties.length; ++i) {
      logObjectProperty(value.objectValue().properties[i], i);
    }
  }
  
  function logState(IJSInterpreter.State memory state) public view {
    console.log('[State]');
    console.log('  identifierCount: %d', state.identifierStates.length);
    console.log('  firstValueSrcNode: %d', state.firstValueSrcNode);
    for (uint i = 0; i < state.identifierStates.length; ++i) {
      logIdentifierState(state.identifierStates[i]);
    }
    console.log('[End State]');
  }
  
  function logIdentifierState(IJSInterpreter.IdentifierState memory state) public view {
    console.log('[IdentifierState]');
    console.log('  name: %s', state.name);
    console.log('  value:');
    logJSValue(state.value);
  }

  function logArrayElement(IJSInterpreter.JSArrayElement memory elem, uint index) public view {
    console.log('[JSArrayElement] %d', index);
    console.log('  arrayElmentIndexesLength: %d', elem.arrayElmentIndexes().length);
    for (uint i = 0; i < elem.arrayElmentIndexes().length; ++i) {
      console.log('    index: %d', elem.arrayElmentIndexes()[i]);
    }
    console.log('  valueType: %s', _toString(elem.valueType));
    console.log('  numberValue: %d', elem.numberValue());
    console.log('  stringValue: %s', elem.stringValue());
//    console.log('  numberSign: %s', _toString(elem.numberSign));
//    console.log('  boolValue: %s', _toString(elem.boolValue()));
  }
  
  function logObjectProperty(IJSInterpreter.JSObjectProperty memory prop, uint index) public view {
    console.log('[JSObjectProperty] %d', index);
    console.log('  key: %s', prop.key);
    console.log('  keyHash: %s', string(abi.encodePacked(prop.keyHash)));
    console.log('  valueType: %s', _toString(prop.valueType));
    console.log('  numberValue: %d', prop.numberValue());
    console.log('  stringValue: %s', prop.stringValue());
    console.log('  numberSign: %s', _toString(prop.numberSign));
    console.log('  boolValue: %s', _toString(prop.boolValue()));
    console.log('  objectPropertyIndexesLength: %d', prop.objectPropertyIndexes().length);
    for (uint i = 0; i < prop.objectPropertyIndexes().length; ++i) {
      console.log('    propertyIndex: %d', prop.objectPropertyIndexes()[i]);
    }
  }

  function _toString(bool b) private pure returns (string memory) {
    return b ? 'true' : 'false';
  }

  function _toString(IJSInterpreter.JSValueType valueType) private pure returns (string memory) {
    if (valueType == IJSInterpreter.JSValueType.value_string) {
      return 'value_string';
    } else if (valueType == IJSInterpreter.JSValueType.value_numberString) {
      return 'value_numberString';
    } else if (valueType == IJSInterpreter.JSValueType.value_boolean) {
      return 'value_boolean';
    } else if (valueType == IJSInterpreter.JSValueType.value_number) {
      return 'value_number';
    } else if (valueType == IJSInterpreter.JSValueType.value_regex) {
      return 'value_regex';
    } else if (valueType == IJSInterpreter.JSValueType.value_array) {
      return 'value_array';
    } else if (valueType == IJSInterpreter.JSValueType.value_object) {
      return 'value_object';
    } else if (valueType == IJSInterpreter.JSValueType.value_null) {
      return 'value_null';
    } else if (valueType == IJSInterpreter.JSValueType.value_undefined) {
      return 'value_undefined';
    } else if (valueType == IJSInterpreter.JSValueType.value_nan) {
      return 'value_nan';
    } else if (valueType == IJSInterpreter.JSValueType.value_infinity) {
      return 'value_infinity';
    } else if (valueType == IJSInterpreter.JSValueType.value_bytes) {
      return 'value_bytes';
    } else if (valueType == IJSInterpreter.JSValueType.value_function) {
      return 'value_function';
    } else if (valueType == IJSInterpreter.JSValueType.value_reference) {
      return 'value_reference';
    }
    return 'invalid';
  }
  function _toString(IAstBuilder.NodeType nodeType) private pure returns (string memory) {
    if (nodeType == IAstBuilder.NodeType.program) {
      return 'program';
    } else if (nodeType == IAstBuilder.NodeType.identifier) {
      return 'identifier';
    } else if (nodeType == IAstBuilder.NodeType.literal) {
      return 'literal';
    } else if (nodeType == IAstBuilder.NodeType.functionDeclaration) {
      return 'functionDeclaration';
    } else if (nodeType == IAstBuilder.NodeType.variableDeclaration) {
      return 'variableDeclaration';
    } else if (nodeType == IAstBuilder.NodeType.variableDeclarator) {
      return 'variableDeclarator';
    } else if (nodeType == IAstBuilder.NodeType.expressionStatement) {
      return 'expressionStatement';
    } else if (nodeType == IAstBuilder.NodeType.returnStatement) {
      return 'returnStatement';
    } else if (nodeType == IAstBuilder.NodeType.breakStatement) {
      return 'breakStatement';
    } else if (nodeType == IAstBuilder.NodeType.continueStatement) {
      return 'continueStatement';
    } else if (nodeType == IAstBuilder.NodeType.blockStatement) {
      return 'blockStatement';
    } else if (nodeType == IAstBuilder.NodeType.ifStatement) {
      return 'ifStatement';
    } else if (nodeType == IAstBuilder.NodeType.whileStatement) {
      return 'whileStatement';
    } else if (nodeType == IAstBuilder.NodeType.forStatement) {
      return 'forStatement';
    } else if (nodeType == IAstBuilder.NodeType.forInStatement) {
      return 'forInStatement';
    } else if (nodeType == IAstBuilder.NodeType.unaryExpression) {
      return 'unaryExpression';
    } else if (nodeType == IAstBuilder.NodeType.binaryExpression) {
      return 'binaryExpression';
    } else if (nodeType == IAstBuilder.NodeType.logicalExpression) {
      return 'logicalExpression';
    } else if (nodeType == IAstBuilder.NodeType.assignmentExpression) {
      return 'assignmentExpression';
    } else if (nodeType == IAstBuilder.NodeType.updateExpression) {
      return 'updateExpression';
    } else if (nodeType == IAstBuilder.NodeType.memberExpression) {
      return 'memberExpression';
    } else if (nodeType == IAstBuilder.NodeType.objectExpression) {
      return 'objectExpression';
    } else if (nodeType == IAstBuilder.NodeType.callExpression) {
      return 'callExpression';
    } else if (nodeType == IAstBuilder.NodeType.assignmentPattern) {
      return 'assignmentPattern';
    } else if (nodeType == IAstBuilder.NodeType.property) {
      return 'property';
    } else if (nodeType == IAstBuilder.NodeType.nullNode) {
      return 'nullNode';
    }
    return 'unknown';
  }
}