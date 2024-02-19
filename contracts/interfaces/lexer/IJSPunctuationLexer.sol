// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSLexer.sol';

/**
 * The interface to extract punctuation tokens.
 */
interface IJSPunctuationLexer {
  enum PunctuationCode {
    leftParenthesis, 
    rightParenthesis, 
    leftSquareBracket, 
    rightSquareBracket, 
    leftCurlyBrace, 
    rightCurlyBrace, 
    semicolon, 
    colon, 
    comma, 
    hash, 
    hashSquareBracket,
    hashCurlyBrace, 
    rightSqquareBracketBar, 
    leftBarSquareBracket, 
    leftCurlyBraceBar, 
    arrow, 
    atMark 
  }
  
  /**
   * extract a punctuation token starting with hash character 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The punctuation token.
   */
  function readHashToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external view returns (IJSLexer.Token memory);
  
  // Get the attributes for leftParenthesis
  function leftParenthesis() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for rightParenthesis
  function rightParenthesis() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for leftSquareBracket
  function leftSquareBracket() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for rightSquareBracket
  function rightSquareBracket() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for leftCurlyBrace
  function leftCurlyBrace() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for rightCurlyBrace
  function rightCurlyBrace() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for semicolon
  function semicolon() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for colon
  function colon() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for comma
  function comma() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for hash
  function hash() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for hashSquareBracket
  function hashSquareBracket() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for hashCurlyBrace
  function hashCurlyBrace() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for rightSqquareBracketBar
  function rightSqquareBracketBar() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for leftBarSquareBracket
  function leftBarSquareBracket() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for leftCurlyBraceBar
  function leftCurlyBraceBar() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for arrow
  function arrow() external pure returns (IJSLexer.TokenAttrs memory);
  // Get the attributes for atMark
  function atMark() external pure returns (IJSLexer.TokenAttrs memory);
}