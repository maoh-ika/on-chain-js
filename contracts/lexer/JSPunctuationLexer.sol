// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import '../interfaces/lexer/IJSPunctuationLexer.sol';
import '../utf8/Utf8.sol';

/**
 * The lexer for punctuation tokens.
 */
contract JSPunctuationLexer is IJSPunctuationLexer {
  struct Punctuation {
    // raw expression in the source code
    string expression;
    PunctuationCode tokenCode;
    // bytes size of the punctuaion
    uint8 size;
    // a flag indicating wether regex can be followed after the punctuation
    bool allowFollowingRegex;
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
  ) external view returns (IJSLexer.Token memory) {
    console.log('_readHashToken');
    IUtf8Char.Utf8Char memory currentChar = Utf8.getNextCharacter(source, context.currentPos);
    require(currentChar.code == 0x23); // #
    uint nextPos = context.currentPos + currentChar.size;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, nextPos);
    
    if (nextChar.code == 0x5B) { // #[
      return _createToken(this.hashSquareBracket(), context);
    } else if (nextChar.code == 0x7B) { // #{
      return _createToken(this.hashCurlyBrace(), context);
    } else { // #
      return _createToken(this.hash(), context);
    }
  }
  
  function leftParenthesis() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '(', tokenCode: PunctuationCode.leftParenthesis, size: 1, allowFollowingRegex: true }));
  }

  function rightParenthesis() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: ')', tokenCode: PunctuationCode.rightParenthesis, size: 1, allowFollowingRegex: false }));
  }

  function leftSquareBracket() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '[', tokenCode: PunctuationCode.leftSquareBracket, size: 1, allowFollowingRegex: true }));
  }

  function rightSquareBracket() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: ']', tokenCode: PunctuationCode.rightSquareBracket, size: 1, allowFollowingRegex: false }));
  }

  function leftCurlyBrace() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '{', tokenCode: PunctuationCode.leftCurlyBrace, size: 1, allowFollowingRegex: true }));
  }

  function rightCurlyBrace() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '}', tokenCode: PunctuationCode.rightCurlyBrace, size: 1, allowFollowingRegex: false }));
  }

  function semicolon() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: ';', tokenCode: PunctuationCode.semicolon, size: 1, allowFollowingRegex: true }));
  }

  function colon() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: ':', tokenCode: PunctuationCode.colon, size: 1, allowFollowingRegex: true }));
  }

  function comma() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: ',', tokenCode: PunctuationCode.comma, size: 1, allowFollowingRegex: true }));
  }

  function hash() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '#', tokenCode: PunctuationCode.hash, size: 1, allowFollowingRegex: false }));
  }

  function hashSquareBracket() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '#[', tokenCode: PunctuationCode.hashSquareBracket, size: 2, allowFollowingRegex: true }));
  }

  function hashCurlyBrace() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '#{', tokenCode: PunctuationCode.hashCurlyBrace, size: 2, allowFollowingRegex: true }));
  }

  function rightSqquareBracketBar() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '[|', tokenCode: PunctuationCode.rightSqquareBracketBar, size: 2, allowFollowingRegex: true }));
  }

  function leftBarSquareBracket() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '|]', tokenCode: PunctuationCode.leftBarSquareBracket, size: 2, allowFollowingRegex: false }));
  }

  function leftCurlyBraceBar() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '{|', tokenCode: PunctuationCode.leftCurlyBraceBar, size: 2, allowFollowingRegex: true }));
  }

  function arrow() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '=>', tokenCode: PunctuationCode.arrow, size: 2, allowFollowingRegex: false }));
  }

  function atMark() external pure override returns (IJSLexer.TokenAttrs memory) {
    return _createPunctuationAttrs(Punctuation({ expression: '@', tokenCode: PunctuationCode.atMark, size: 1 , allowFollowingRegex: false }));
  }
  
  /**
   * create punctuation token attributes
   * @param punctuation punctuation params
   * @return The punctuation token attributes.
   */
  function _createPunctuationAttrs(Punctuation memory punctuation) private pure returns (IJSLexer.TokenAttrs memory) {
    return IJSLexer.TokenAttrs({
      value: abi.encode(punctuation.expression), // encode into bytes. use TokenAttrsUtil.decodePunctuationValue for decode
      tokenType: IJSLexer.TokenType.punctuation,
      tokenCode: uint(punctuation.tokenCode),
      size: punctuation.size,
      allowFollowingRegex: punctuation.allowFollowingRegex
    });
  }
  
  /**
   * extract a punctuation token
   * @param attrs token attributes
   * @param context Tokenization context.
   * @return The punctuation token.
   */
  function _createToken(IJSLexer.TokenAttrs memory attrs, IJSLexer.Context memory context) internal pure returns (IJSLexer.Token memory) {
    return IJSLexer.Token({
      attrs: attrs,
      startPos: context.currentPos,
      endPos: context.currentPos + attrs.size - 1,
      line: context.currentLine
    });
  }
}
