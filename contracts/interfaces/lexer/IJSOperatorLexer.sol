// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSLexer.sol';

/**
 * The interface to operator tokens.
 */
interface IJSOperatorLexer {
  enum OperatorCode {
    nullishCoalescing, // 0
    nullishCoalescingAssignment, // 1
    optionalChaining, // 2
    question, // 3
    division, // 4
    divisionAssignment, // 5
    multiplication, // 6
    MultiplicationAssignment, // 7
    exponentiation, // 8 
    exponentiationAssignment, // 9
    remainder, // 10
    remainderAssignment, // 11
    bitwiseOr, // 12
    bitwiseOrAssignment, // 13
    logicalOr, // 14
    logicalOrAssignment, // 15
    bitwiseAnd, // 16
    bitwiseAndAssignment, // 17
    logicalAnd, // 18
    logicalAndAssignment, // 19
    bitwiseXor, // 20
    bitwiseXorAssignment, // 21
    addition, // 22
    additionAssignment, // 23
    increment, // 24
    subtraction, // 25
    subtractionAssignment, // 26
    decrement, // 27
    greaterThan, // 28
    greaterThanOrEqual, // 29
    rightShift, // 30
    rightShiftAssignment, // 31
    unsignedRightShift, // 32
    unsignedRightShiftAssignment, // 33
    lessThan, // 34
    lessThanOrEqual, // 35
    leftShift, // 36
    leftShiftAssignment, // 37
    assignment, // 38
    equality, // 39
    strictEquality, // 40
    logicalNot, // 41
    inequality, // 42
    strictInequality, // 43
    bitwiseNot, // 44
    dot, // 45
    spread // 46
  }
  
  struct Operator {
    // raw expression in the source code
    string expression;
    OperatorCode operatorCode;
    // byte size of the operator.
    uint size;
    // a flag indicating wether regex can be followed after this operator
    bool allowFollowingRegex;
  }

  /**
   * extract a operator token starting with quastion mark
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readQuestionToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with slash 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readSlashToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with asterisk
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readAsteriskToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with percent mark
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readPercentToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with bar character 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readBarToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with ampersand 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readAmpToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with caret
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readCaretToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with plus character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readPlusToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with minus character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readMinusToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with > character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readGreaterThanToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with < character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readLessThanToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with exclamation mark 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readExclamationToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with =
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readEqualToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with dot character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readDotToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
  
  /**
   * extract a operator token starting with tilde
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readTildeToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory);
}