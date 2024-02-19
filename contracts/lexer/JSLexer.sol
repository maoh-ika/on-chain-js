// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import "../utils/Log.sol";
import { IJSLexer } from '../interfaces/lexer/IJSLexer.sol';
import { IJSStringLexer } from '../interfaces/lexer/IJSStringLexer.sol';
import { IJSNumberLexer } from '../interfaces/lexer/IJSNumberLexer.sol';
import { IJSPunctuationLexer } from '../interfaces/lexer/IJSPunctuationLexer.sol';
import { IJSKeywordLexer } from '../interfaces/lexer/IJSKeywordLexer.sol';
import { IJSOperatorLexer } from '../interfaces/lexer/IJSOperatorLexer.sol';
import { IJSRegexLexer } from '../interfaces/lexer/IJSRegexLexer.sol';
import { IJSIdentifierLexer } from '../interfaces/lexer/IJSIdentifierLexer.sol';
import '../utf8/Utf8.sol';
import './SkipUtil.sol';
import './TokenAttrsUtil.sol';

/**
 * access control for lexers update
 */
contract JSLexerAdmin is Ownable {
  // address with permission to update lexers
  address public admin;

  IJSStringLexer public stringLexer;
  IJSNumberLexer public numberLexer;
  IJSPunctuationLexer public punctuationLexer;
  IJSKeywordLexer public keywordLexer;
  IJSOperatorLexer public operatorLexer;
  IJSRegexLexer public regexLexer;
  IJSIdentifierLexer public identifierLexer;

  constructor(
    IJSStringLexer _stringLexer,
    IJSNumberLexer _numberLexer,
    IJSPunctuationLexer _punctuationLexer,
    IJSKeywordLexer _keywordLexer,
    IJSOperatorLexer _operatorLexer,
    IJSRegexLexer _regexLexer,
    IJSIdentifierLexer _identifierLexer
  ) {
    admin = owner();
    stringLexer = _stringLexer;
    numberLexer = _numberLexer;
    punctuationLexer = _punctuationLexer;
    keywordLexer = _keywordLexer;
    operatorLexer = _operatorLexer;
    regexLexer = _regexLexer;
    identifierLexer = _identifierLexer;
  }

  /**
   * Ristrict access to admin
   */
  modifier onlyAdmin() {
    require(owner() == msg.sender || admin == msg.sender, 'only admin');
    _;
  }

  /**
   * Set admin address
   */
  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }

  /**
   * Update string lexer implementation
   */
  function setStringLexer(IJSStringLexer _stringLexer) external onlyAdmin {
    stringLexer = _stringLexer;
  }

  /**
   * Update number lexer implementation
   */
  function setNumberLexer(IJSNumberLexer _numberLexer) external onlyAdmin {
    numberLexer = _numberLexer;
  }

  /**
   * Update punctuation lexer implementation
   */
  function setPunctuationLexer(IJSPunctuationLexer _punctuationLexer) external onlyAdmin {
    punctuationLexer = _punctuationLexer;
  }

  /**
   * Update keyword lexer implementation
   */
  function setKeywordLexer(IJSKeywordLexer _keywordLexer) external onlyAdmin {
    keywordLexer = _keywordLexer;
  }

  /**
   * Update operator lexer implementation
   */
  function setOperatorLexer(IJSOperatorLexer _operatorLexer) external onlyAdmin {
    operatorLexer = _operatorLexer;
  }

  /**
   * Update regex lexer implementation
   */
  function setRegexLexer(IJSRegexLexer _regexLexer) external onlyAdmin {
    regexLexer = _regexLexer;
  }

  /**
   * Update identifier lexer implementation
   */
  function setIdentifierLexer(IJSIdentifierLexer _identifierLexer) external onlyAdmin {
    identifierLexer = _identifierLexer;
  }
}

/**
 * The entry point lexer for tokenizing.
 */
contract JSLexer is JSLexerAdmin, IJSLexer {
  constructor(
    IJSStringLexer _stringLexer,
    IJSNumberLexer _numberLexer,
    IJSPunctuationLexer _punctuationLexer,
    IJSKeywordLexer _keywordLexer,
    IJSOperatorLexer _operatorLexer,
    IJSRegexLexer _regexLexer,
    IJSIdentifierLexer _identifierLexer
  ) JSLexerAdmin(_stringLexer, _numberLexer, _punctuationLexer, _keywordLexer, _operatorLexer, _regexLexer, _identifierLexer) {}

  /**
   * Tokenize the source code.
   * @param code source code
   * @param config tokenization configuration
   * @return token array
   */
  function tokenize(string calldata code, Config calldata config) external view override returns (Token[] memory) {
    bytes calldata sourceBytes = bytes(code);
    uint tokenCount = 0;
    uint tokenArrayPageSize = 50;
    Token memory initToken;
    initToken.attrs.tokenType = TokenType.start;
    Context memory context;
    context.eofPos = uint(sourceBytes.length);
    Token[] memory tokens = new Token[](tokenArrayPageSize);

    while (context.currentPos < context.eofPos) {
      Token memory token = _nextToken(sourceBytes, context);
      // Log.logToken(token);
      if (
        token.attrs.tokenType == IJSLexer.TokenType.invalid ||
        (token.attrs.tokenType == IJSLexer.TokenType.comment && config.ignoreComment)
      ) {
        continue;
      }
      tokens[tokenCount++] = token;

      if (tokenCount % tokenArrayPageSize == 0) {
        tokens = _resize(tokens, uint(tokens.length) + tokenArrayPageSize);
      }
      context.allowFollowingRegex = token.attrs.allowFollowingRegex;
    }

    // cut of redundant elements
    tokens = _resize(tokens, tokenCount);
    return tokens;
  }

  /**
   * Extract a token. Read next character and dispach a tokenizing task to the appropriate lexer.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _nextToken(
    bytes calldata source,
    Context memory context
  ) private view returns (IJSLexer.Token memory) {
    Token memory token;
    SkipUtil.skipSpaces(source, context);
    if (context.eofPos <= context.currentPos) { // ends with space
      return token;
    }

    IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, context.currentPos);
    if (char.code == 0x28) { // leftParenthesis
      token = _createToken(punctuationLexer.leftParenthesis(), context);
    } else if (char.code == 0x29) { // rightParenthesis
      token = _createToken(punctuationLexer.rightParenthesis(), context);
    } else if (char.code == 0x3B) { // semicolon
      token = _createToken(punctuationLexer.semicolon(), context);
    } else if (char.code == 0x23) { // numberSign
      token = punctuationLexer.readHashToken(source, context);
    } else if (char.code == 0x2C) { // comma
      token = _createToken(punctuationLexer.comma(), context);
    } else if (char.code == 0x5B) { // leftSquareBracket
      token = _createToken(punctuationLexer.leftSquareBracket(), context);
    } else if (char.code == 0x5D) { // rightSquareBracket
      token = _createToken(punctuationLexer.rightSquareBracket(), context);
    } else if (char.code == 0x7B) { // leftCurlyBrace
      token = _createToken(punctuationLexer.leftCurlyBrace(), context);
    } else if (char.code == 0x7D) { // rightCurlyBrace
      token = _createToken(punctuationLexer.rightCurlyBrace(), context);
    } else if (char.code == 0x3A) { // colon
      token = _createToken(punctuationLexer.colon(), context);
    } else if (char.code == 0x3F) { // questionMark
      token = operatorLexer.readQuestionToken(source, context);
    } else if (char.code == 0x60) { // backquote
      token = stringLexer.readStringToken(source, context, char);
    } else if (char.code == 0x30) { // zero
      token = numberLexer.readZeroToken(source, context);
    } else if (Utf8.isDigit(char.code)) {
      token = numberLexer.readNumberToken(source, context);
    } else if (char.code == 0x27 || char.code == 0x22) { // singleQuote, doubleQuote
      token = stringLexer.readStringToken(source, context, char);
    } else if (char.code == 0x2F) { // slash
      IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, context.currentPos + 1);
      if (nextChar.code == 0x2F) { // line comment
        token = _readLineCommentToken(source, context);
      } else if (nextChar.code == 0x2A) { // block comment
        token = _readBlockCommentToken(source, context);
      } else {
        token = _readSlashToken(source, context);
      }
    } else if (char.code == 0x2A) { // asterisk
      token = operatorLexer.readAsteriskToken(source, context);
    } else if (char.code == 0x25) { // percentSign
      token = operatorLexer.readPercentToken(source, context);
    } else if (char.code == 0x7C) { // verticalBar
      token = operatorLexer.readBarToken(source, context);
    } else if (char.code == 0x26) { // ampersand
      token = operatorLexer.readAmpToken(source, context);
    } else if (char.code == 0x5E) { // caret
      token = operatorLexer.readCaretToken(source, context);
    } else if (char.code == 0x2B) { // plusSign
      token = operatorLexer.readPlusToken(source, context);
    } else if (char.code == 0x2D) { // minusSign
      token = _readMinusToken(source, context);
    } else if (char.code == 0x3E) { // greaterThanSign
      token = operatorLexer.readGreaterThanToken(source, context);
    } else if (char.code == 0x3C) { // lessThanSign
      token = operatorLexer.readLessThanToken(source, context);
    } else if (char.code == 0x21) { // exclamationMark
      token = operatorLexer.readExclamationToken(source, context);
    } else if (char.code == 0x3D) { // equal
      token = _readEqualToken(source, context);
    } else if (char.code == 0x7E) { // tilde
      token = operatorLexer.readTildeToken(source, context);
    } else if (char.code == 0x40) { // atMark
      token = _createToken(punctuationLexer.atMark(), context);
    } else if (char.code == 0x5C) { // backSlash
      token = _readWordToken(source, context);
    } else if (char.code == 0x2E) { // dot
      token = _readDotToken(source, context);
    } else {
      if (identifierLexer.isIdentifierStart(char.code)) {
        token = _readWordToken(source, context);
      } else {
        revert('syntax error');
      }
    }
    
    context.currentPos += token.attrs.size;
    return token;
  }

  /**
   * Extract a token starting with slash
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readSlashToken(
    bytes calldata source,
    Context memory context 
  ) private view returns (IJSLexer.Token memory) {
    if (context.allowFollowingRegex) {
      return regexLexer.readRegexToken(source, context);
    } else {
      return operatorLexer.readSlashToken(source, context);
    }
  }
  
  /**
   * Extract a token starting with minus symbol
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readMinusToken(
    bytes calldata source,
    Context memory context 
  ) private view returns (IJSLexer.Token memory) {
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, context.currentPos + 1);
    if (nextChar.code == 0x30 /* zero */ || Utf8.isDigit(nextChar.code)) {
      return numberLexer.readMinusNumberToken(source, context);
    } else {
      return operatorLexer.readMinusToken(source, context);
    }
  }

  /**
   * Extract a token starting with equal symbol
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readEqualToken(
    bytes calldata source,
    Context memory context 
  ) private view returns (IJSLexer.Token memory) {
    if (Utf8.getNextCharacter(source, context.currentPos + 1).code == 0x3E) { // greaterThanSign
      return _createToken(punctuationLexer.arrow(), context);
    } else {
      return operatorLexer.readEqualToken(source, context);
    }
  }

  /**
   * Extract a keyword token
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readWordToken(
    bytes calldata source,
    Context memory context 
  ) private view returns (IJSLexer.Token memory) {
    Token memory idToken = identifierLexer.readIdentifierToken(source, context);
    (string memory identifier,) = TokenAttrsUtil.decodeIdentifierValue(idToken.attrs);
    // Is the extracted identifier reserved word ?
    TokenAttrs memory keywordAttrs = keywordLexer.getKeywordAttr(identifier);
    return keywordAttrs.size > 0 ? _createToken(keywordAttrs, context) : idToken;
  }

  /**
   * Extract a token starting with dot symbol
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readDotToken(
    bytes calldata source,
    Context memory context 
  ) private view returns (IJSLexer.Token memory) {
    IUtf8Char.Utf8Char memory nextDotChar = Utf8.getNextCharacter(source, context.currentPos + 1);
    if (0x30 <= nextDotChar.code && nextDotChar.code <= 0x39) { // 0 - 9
      return numberLexer.readNumberToken(source, context);
    } else {
      return operatorLexer.readDotToken(source, context);
    }
  }

  /**
   * Extract a line comment token 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readLineCommentToken(
    bytes calldata source,
    Context memory context
  ) private pure returns (IJSLexer.Token memory) {
    uint curPos = context.currentPos;
    while (curPos < context.eofPos) {
      IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, curPos);
      if (char.size == 0) {
        break; // unknown char
      }
      curPos += char.size;
      if (Utf8.isNewLine(char.code)) {
        ++context.currentLine;
        break;
      }
    }
    IJSLexer.TokenAttrs memory attrs;
    attrs.value = abi.encode(string(source[context.currentPos:curPos]));
    attrs.size = curPos - context.currentPos;
    attrs.tokenType = IJSLexer.TokenType.comment;
    attrs.tokenCode = 0; // line comment
    return _createToken(attrs, context);
  }
  
  /**
   * Extract a block comment token 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readBlockCommentToken(
    bytes calldata source,
    Context memory context
  ) private pure returns (IJSLexer.Token memory) {
    uint curPos = context.currentPos;
    while (curPos < context.eofPos) {
      IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, curPos);
      if (char.size == 0) {
        break; // unknown char
      }
      if (char.code == 0x2A /* * */) {
        if (Utf8.getNextCharacter(source, curPos + 1).code == 0x2F /* / */) {
          curPos += 2;
          break;
        }
      } else if (Utf8.isNewLine(char.code)) {
        ++context.currentLine;
      }
      curPos += char.size;
    }
    IJSLexer.TokenAttrs memory attrs;
    attrs.value = abi.encode(string(source[context.currentPos:curPos]));
    attrs.size = curPos - context.currentPos;
    attrs.tokenType = IJSLexer.TokenType.comment;
    attrs.tokenCode = 1; // block comment
    return _createToken(attrs, context);
  }

  /**
   * Create a token
   * @param attrs token attributes.
   * @param context Tokenization context.
   * @return The token.
   */
  function _createToken(TokenAttrs memory attrs, Context memory context) private pure returns (IJSLexer.Token memory) {
    return IJSLexer.Token({
      attrs: attrs,
      startPos: context.currentPos,
      endPos: context.currentPos + attrs.size - 1,
      line: context.currentLine
    });
  }

  /**
   * Resize the token array
   * @param tokens token array.
   * @param size target size.
   * @return new token array.
   */
  function _resize(Token[] memory tokens, uint size) private pure returns (Token[] memory) {
    Token[] memory newArray = new Token[](size);
    for (uint i = 0; i < tokens.length && i < size; i++) {
      newArray[i] = tokens[i];
    }
    return newArray;
  }
}