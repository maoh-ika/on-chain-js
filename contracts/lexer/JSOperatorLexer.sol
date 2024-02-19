// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import '../interfaces/lexer/IJSOperatorLexer.sol';
import '../utf8/Utf8.sol';

/**
 * The lexer for operator tokens.
 */
contract JSOperatorLexer is IJSOperatorLexer {
  /**
   * extract a operator token starting with quastion mark
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readQuestionToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x3F) { // ?
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // ??=
        operator = IJSOperatorLexer.Operator({expression: '??=', operatorCode: IJSOperatorLexer.OperatorCode.nullishCoalescingAssignment, size: 3, allowFollowingRegex: false});
      } else { // ??
        operator = IJSOperatorLexer.Operator({expression: '??', operatorCode: IJSOperatorLexer.OperatorCode.nullishCoalescing, size: 2, allowFollowingRegex: true});
      }
    } else if (nextChar.code == 0x2E) { // ?.
      operator = IJSOperatorLexer.Operator({expression: '?.', operatorCode: IJSOperatorLexer.OperatorCode.optionalChaining, size: 2, allowFollowingRegex: false});
    } else { // ?
      operator = IJSOperatorLexer.Operator({expression: '?', operatorCode: IJSOperatorLexer.OperatorCode.question, size: 1, allowFollowingRegex: true});
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with slash 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readSlashToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    IUtf8Char.Utf8Char memory equalChar = Utf8.getNextCharacter(source, context.currentPos + 1);
    if (equalChar.code == 0x3D) { // /=
      operator = IJSOperatorLexer.Operator({expression: '/=', operatorCode: IJSOperatorLexer.OperatorCode.divisionAssignment, size: 2, allowFollowingRegex: true});
    } else { // /
      operator = IJSOperatorLexer.Operator({expression: '/', operatorCode: IJSOperatorLexer.OperatorCode.division, size: 1, allowFollowingRegex: false });
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with asterisk
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readAsteriskToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x2A) {
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // **=
        operator = IJSOperatorLexer.Operator({expression: '**=', operatorCode: IJSOperatorLexer.OperatorCode.exponentiationAssignment, size: 3, allowFollowingRegex: true});
      } else { // **
        operator = IJSOperatorLexer.Operator({expression: '**', operatorCode: IJSOperatorLexer.OperatorCode.exponentiation, size: 2, allowFollowingRegex: true});
      }
    } else {
      if (nextChar.code == 0x3D) { // *=
        operator = IJSOperatorLexer.Operator({expression: '*=', operatorCode: IJSOperatorLexer.OperatorCode.MultiplicationAssignment, size: 2, allowFollowingRegex: true});
      } else { // *
        operator = IJSOperatorLexer.Operator({expression: '*', operatorCode: IJSOperatorLexer.OperatorCode.multiplication, size: 1, allowFollowingRegex: false });
      }
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with percent mark
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readPercentToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    IUtf8Char.Utf8Char memory equalChar = Utf8.getNextCharacter(source, context.currentPos + 1);
    if (equalChar.code == 0x3D) { // %=
      operator = IJSOperatorLexer.Operator({expression: '%=', operatorCode: IJSOperatorLexer.OperatorCode.remainderAssignment, size: 2, allowFollowingRegex: true});
    } else { // %
      operator = IJSOperatorLexer.Operator({expression: '%', operatorCode: IJSOperatorLexer.OperatorCode.remainder, size: 1, allowFollowingRegex: true});
    }
    return _createToken(operator, context);
  }

  /**
   * extract a operator token starting with bar character 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readBarToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x7C) { // |
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // ||=
        operator = IJSOperatorLexer.Operator({expression: '||=', operatorCode: IJSOperatorLexer.OperatorCode.logicalOrAssignment, size: 3, allowFollowingRegex: true});
      } else { // ||
        operator = IJSOperatorLexer.Operator({expression: '||', operatorCode: IJSOperatorLexer.OperatorCode.logicalOr, size: 2, allowFollowingRegex: true});
      }
    } else {
      if (nextChar.code == 0x3D) { // |=
        operator = IJSOperatorLexer.Operator({expression: '|=', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseOrAssignment, size: 2, allowFollowingRegex: true});
      } else { // |
        operator = IJSOperatorLexer.Operator({expression: '|', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseOr, size: 1, allowFollowingRegex: true});
      }
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with ampersand 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readAmpToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x26) {
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // &&=
        operator = IJSOperatorLexer.Operator({expression: '&&=', operatorCode: IJSOperatorLexer.OperatorCode.logicalAndAssignment, size: 3, allowFollowingRegex: true});
      } else { // &&
        operator = IJSOperatorLexer.Operator({expression: '&&', operatorCode: IJSOperatorLexer.OperatorCode.logicalAnd, size: 2, allowFollowingRegex: true});
      }
    } else {
      if (nextChar.code == 0x3D) { // &=
        operator = IJSOperatorLexer.Operator({expression: '&=', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseAndAssignment, size:2, allowFollowingRegex: true});
      } else { // &
        operator = IJSOperatorLexer.Operator({expression: '&', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseAnd, size: 1, allowFollowingRegex: true});
      }
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with caret
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readCaretToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x3D) { // ^=
      operator = IJSOperatorLexer.Operator({expression: '^=', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseXorAssignment, size: 2, allowFollowingRegex: true});
    } else { // ^
      operator = IJSOperatorLexer.Operator({expression: '^', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseXor, size: 1, allowFollowingRegex: true});
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with plus character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readPlusToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x2B) { // ++
      operator = IJSOperatorLexer.Operator({expression: '++', operatorCode: IJSOperatorLexer.OperatorCode.increment, size: 2, allowFollowingRegex: false});
    } else {
      if (nextChar.code == 0x3D) { // +=
        operator = IJSOperatorLexer.Operator({expression: '+=', operatorCode: IJSOperatorLexer.OperatorCode.additionAssignment, size: 2, allowFollowingRegex: true});
      } else { // +
        operator = IJSOperatorLexer.Operator({expression: '+', operatorCode: IJSOperatorLexer.OperatorCode.addition, size: 1, allowFollowingRegex: true});
      }
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with minus character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readMinusToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x2D) { // --
      operator = IJSOperatorLexer.Operator({expression: '--', operatorCode: IJSOperatorLexer.OperatorCode.decrement, size: 2, allowFollowingRegex: false});
    } else {
      if (nextChar.code == 0x3D) { // -=
        operator = IJSOperatorLexer.Operator({expression: '-=', operatorCode: IJSOperatorLexer.OperatorCode.subtractionAssignment, size: 2, allowFollowingRegex: true});
      } else { // -
        operator = IJSOperatorLexer.Operator({expression: '-', operatorCode: IJSOperatorLexer.OperatorCode.subtraction, size: 1, allowFollowingRegex: true});
      }
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with > character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readGreaterThanToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x3E) { // >>
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3E) { // >>>
        ++currentPos;
        nextChar = Utf8.getNextCharacter(source, currentPos);
        if (nextChar.code == 0x3D) { // >>>=
          operator = IJSOperatorLexer.Operator({expression: '>>>=', operatorCode: IJSOperatorLexer.OperatorCode.unsignedRightShiftAssignment, size: 4, allowFollowingRegex: true});
        } else { // >>>
          operator = IJSOperatorLexer.Operator({expression: '>>>', operatorCode: IJSOperatorLexer.OperatorCode.unsignedRightShift, size: 3, allowFollowingRegex: true});
        }
      } else {
        if (nextChar.code == 0x3D) { // >>=
          operator = IJSOperatorLexer.Operator({expression: '>>=', operatorCode: IJSOperatorLexer.OperatorCode.rightShiftAssignment, size: 3, allowFollowingRegex: true});
        } else { // >>
          operator = IJSOperatorLexer.Operator({expression: '>>', operatorCode: IJSOperatorLexer.OperatorCode.rightShift, size: 2, allowFollowingRegex: true});
        }
      }
    } else { // >ure
      if (nextChar.code == 0x3D) { // >=
        operator = IJSOperatorLexer.Operator({expression: '>=', operatorCode: IJSOperatorLexer.OperatorCode.greaterThanOrEqual, size: 2, allowFollowingRegex: true});
      } else { // >
        operator = IJSOperatorLexer.Operator({expression: '>', operatorCode: IJSOperatorLexer.OperatorCode.greaterThan, size: 1, allowFollowingRegex: true});
      }
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with < character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readLessThanToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    // todo: xml like comment
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x3C) { // <<
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // <<=
        operator = IJSOperatorLexer.Operator({expression: '<<=', operatorCode: IJSOperatorLexer.OperatorCode.leftShiftAssignment, size: 3, allowFollowingRegex: true});
      } else { // <<
        operator = IJSOperatorLexer.Operator({expression: '<<', operatorCode: IJSOperatorLexer.OperatorCode.leftShift, size: 2, allowFollowingRegex: true});
      }
    } else { // <
      if (nextChar.code == 0x3D) { // <=
        operator = IJSOperatorLexer.Operator({expression: '<=', operatorCode: IJSOperatorLexer.OperatorCode.lessThanOrEqual, size: 2, allowFollowingRegex: true});
      } else { // <
        operator = IJSOperatorLexer.Operator({expression: '<', operatorCode: IJSOperatorLexer.OperatorCode.lessThan, size: 1, allowFollowingRegex: true});
      }
    }

    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with exclamation mark 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readExclamationToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x3D) {
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // !==
        operator = IJSOperatorLexer.Operator({expression: '!==', operatorCode: IJSOperatorLexer.OperatorCode.strictInequality, size: 3, allowFollowingRegex: true});
      } else { // !=
        operator = IJSOperatorLexer.Operator({expression: '!=', operatorCode: IJSOperatorLexer.OperatorCode.inequality, size: 2, allowFollowingRegex: true});
      }
    } else { // !
      operator = IJSOperatorLexer.Operator({expression: '!', operatorCode: IJSOperatorLexer.OperatorCode.logicalNot, size: 1, allowFollowingRegex: true});
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with =
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readEqualToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    uint currentPos = context.currentPos + 1;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, currentPos);
    if (nextChar.code == 0x3D) {
      ++currentPos;
      nextChar = Utf8.getNextCharacter(source, currentPos);
      if (nextChar.code == 0x3D) { // ===
        operator = IJSOperatorLexer.Operator({expression: '===', operatorCode: IJSOperatorLexer.OperatorCode.strictEquality, size: 3, allowFollowingRegex: true});
      } else { // ==
        operator = IJSOperatorLexer.Operator({expression: '==', operatorCode: IJSOperatorLexer.OperatorCode.equality, size: 2, allowFollowingRegex: true});
      }
    } else {
      operator = IJSOperatorLexer.Operator({expression: '=', operatorCode: IJSOperatorLexer.OperatorCode.assignment, size: 1, allowFollowingRegex: true});
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with dot character
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readDotToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    Operator memory operator;
    if (
      Utf8.getNextCharacter(source, context.currentPos + 1).code == 0x2E &&
      Utf8.getNextCharacter(source, context.currentPos + 2).code == 0x2E
    ) { // ...
      operator = IJSOperatorLexer.Operator({expression: '...', operatorCode: IJSOperatorLexer.OperatorCode.spread, size: 3, allowFollowingRegex: false});
    } else { // .
      operator = IJSOperatorLexer.Operator({expression: '.', operatorCode: IJSOperatorLexer.OperatorCode.dot, size: 1, allowFollowingRegex: false});
    }
    return _createToken(operator, context);
  }
  
  /**
   * extract a operator token starting with tilde
   * @param context Tokenization context.
   * @return The operator token.
   */
  function readTildeToken(
    bytes calldata,
    IJSLexer.Context memory context 
  ) external pure override returns (IJSLexer.Token memory) {
    return _createToken(IJSOperatorLexer.Operator({expression: '~', operatorCode: IJSOperatorLexer.OperatorCode.bitwiseNot, size: 1, allowFollowingRegex: true}), context);
  }
  
  /**
   * create a operator token
   * @param operator operator params.
   * @param context Tokenization context.
   * @return The operator token.
   */
  function _createToken(Operator memory operator, IJSLexer.Context memory context) internal pure returns (IJSLexer.Token memory) {
    IJSLexer.TokenAttrs memory attrs = IJSLexer.TokenAttrs({
      value: abi.encode(operator.expression),
      tokenType: IJSLexer.TokenType.operator,
      tokenCode: uint(operator.operatorCode),
      size: operator.size,
      allowFollowingRegex: operator.allowFollowingRegex
    });
    return IJSLexer.Token({
      attrs: attrs,
      startPos: context.currentPos,
      endPos: context.currentPos + attrs.size - 1,
      line: context.currentLine
    });
  }
}