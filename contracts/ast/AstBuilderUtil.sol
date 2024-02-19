// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../utils/Log.sol';
import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/lexer/IJSKeywordLexer.sol';
import '../interfaces/lexer/IJSPunctuationLexer.sol';
import '../interfaces/lexer/IJSOperatorLexer.sol';

library AstBuilderUtil {
  /**
   * Get unary operator type corresponding to the token
   * @param tokenCode token code
   * @param tokenType token type
   * @return unary operator type
   */
  function getUnaryOperator(uint tokenCode, IJSLexer.TokenType tokenType) internal pure returns (IAstBuilder.UnaryOperator) {
    if (tokenType == IJSLexer.TokenType.operator) {
      if (tokenCode == uint(IJSOperatorLexer.OperatorCode.subtraction)) {
        return IAstBuilder.UnaryOperator.unary_minus;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.addition)) {
        return IAstBuilder.UnaryOperator.unary_plus;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.logicalNot)) {
        return IAstBuilder.UnaryOperator.unary_logicalNot;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseNot)) {
        return IAstBuilder.UnaryOperator.unary_bitwiseNot;
      }
    } else if (tokenType == IJSLexer.TokenType.keyword) {
      if (tokenCode == uint(IJSKeywordLexer.KeywordCode._typeof)) {
        return IAstBuilder.UnaryOperator.unary_typeof;
      } else if (tokenCode == uint(IJSKeywordLexer.KeywordCode._void)) {
        return IAstBuilder.UnaryOperator.unary_void;
      } else if (tokenCode == uint(IJSKeywordLexer.KeywordCode._delete)) {
        revert('delete not supported');
      }
    }
    return IAstBuilder.UnaryOperator.unary_invalid;
  }

  /**
   * Get binary operator type corresponding to the token
   * @param tokenCode token code
   * @param tokenType token type
   * @return binary operator type
   */
  function getBinaryOperator(uint tokenCode, IJSLexer.TokenType tokenType) internal pure returns (IAstBuilder.BinaryOperator) {
    if (tokenType == IJSLexer.TokenType.keyword) {
      if (tokenCode == uint(IJSKeywordLexer.KeywordCode._in)) {
        return IAstBuilder.BinaryOperator.biop_in;
      } else if (tokenCode == uint(IJSKeywordLexer.KeywordCode._instanceof)) {
        return IAstBuilder.BinaryOperator.biop_instanceof;
      }
    } else if (tokenType == IJSLexer.TokenType.operator) {
      if (tokenCode == uint(IJSOperatorLexer.OperatorCode.equality)) {
        return IAstBuilder.BinaryOperator.biop_equality;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.inequality)) {
        return IAstBuilder.BinaryOperator.biop_inequality;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.strictEquality)) {
        return IAstBuilder.BinaryOperator.biop_strictEquality;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.strictInequality)) {
        return IAstBuilder.BinaryOperator.biop_strictInequality;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.lessThan)) {
        return IAstBuilder.BinaryOperator.biop_lessThan;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.lessThanOrEqual)) {
        return IAstBuilder.BinaryOperator.biop_lessThanOrEqual;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.greaterThan)) {
        return IAstBuilder.BinaryOperator.biop_greaterThan;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.greaterThanOrEqual)) {
        return IAstBuilder.BinaryOperator.biop_greaterThanOrEqual;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.leftShift)) {
        return IAstBuilder.BinaryOperator.biop_leftShift;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.rightShift)) {
        return IAstBuilder.BinaryOperator.biop_rightShift;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.unsignedRightShift)) {
        return IAstBuilder.BinaryOperator.biop_unsignedRightShift;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.addition)) {
        return IAstBuilder.BinaryOperator.biop_addition;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.subtraction)) {
        return IAstBuilder.BinaryOperator.biop_subtraction;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.multiplication)) {
        return IAstBuilder.BinaryOperator.biop_multiplication;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.division)) {
        return IAstBuilder.BinaryOperator.biop_division;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.remainder)) {
        return IAstBuilder.BinaryOperator.biop_remainder;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseOr)) {
        return IAstBuilder.BinaryOperator.biop_bitwiseOr;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseXor)) {
        return IAstBuilder.BinaryOperator.biop_bitwiseXor;
      }else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseAnd)) {
        return IAstBuilder.BinaryOperator.biop_bitwiseAnd;
      }
    }
    return IAstBuilder.BinaryOperator.biop_invalid;
  }
  
  /**
   * Get assignment operator type corresponding to the token
   * @param tokenCode token code
   * @param tokenType token type
   * @return assignment operator type
   */
  function getAssignmentOperator(uint tokenCode, IJSLexer.TokenType tokenType) internal pure returns (IAstBuilder.AssignmentOperator) {
    if (tokenType == IJSLexer.TokenType.operator) {
      if (tokenCode == uint(IJSOperatorLexer.OperatorCode.assignment)) {
        return IAstBuilder.AssignmentOperator.assignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.additionAssignment)) {
        return IAstBuilder.AssignmentOperator.additionAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.subtractionAssignment)) {
        return IAstBuilder.AssignmentOperator.subtractionAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.exponentiationAssignment)) {
        return IAstBuilder.AssignmentOperator.exponentiationAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.divisionAssignment)) {
        return IAstBuilder.AssignmentOperator.divisionAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.remainderAssignment)) {
        return IAstBuilder.AssignmentOperator.remainderAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.leftShiftAssignment)) {
        return IAstBuilder.AssignmentOperator.leftShiftAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.rightShiftAssignment)) {
        return IAstBuilder.AssignmentOperator.rightShiftAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseOrAssignment)) {
        return IAstBuilder.AssignmentOperator.bitwiseOrAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseXorAssignment)) {
        return IAstBuilder.AssignmentOperator.bitwiseXorAssignment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.bitwiseAndAssignment)) {
        return IAstBuilder.AssignmentOperator.bitwiseAndAssignment;
      }
    }
    return IAstBuilder.AssignmentOperator.invalid;
  }

  /**
   * Get update operator type corresponding to the token
   * @param tokenCode token code
   * @param tokenType token type
   * @return update operator type
   */
  function getUpdateOperator(uint tokenCode, IJSLexer.TokenType tokenType) internal pure returns (IAstBuilder.UpdateOperator) {
    if (tokenType == IJSLexer.TokenType.operator) {
      if (tokenCode == uint(IJSOperatorLexer.OperatorCode.increment)) {
        return IAstBuilder.UpdateOperator.update_increment;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.decrement)) {
        return IAstBuilder.UpdateOperator.update_decrement;
      }
    }
    return IAstBuilder.UpdateOperator.update_invalid;
  }

  /**
   * Get logical operator type corresponding to the token
   * @param tokenCode token code
   * @param tokenType token type
   * @return logical operator type
   */
  function getLogicalOperator(uint tokenCode, IJSLexer.TokenType tokenType) internal pure returns (IAstBuilder.LogicalOperator) {
    if (tokenType == IJSLexer.TokenType.operator) {
      if (tokenCode == uint(IJSOperatorLexer.OperatorCode.logicalAnd)) {
        return IAstBuilder.LogicalOperator.logical_and;
      } else if (tokenCode == uint(IJSOperatorLexer.OperatorCode.logicalOr)) {
        return IAstBuilder.LogicalOperator.logical_or;
      }
    }
    return IAstBuilder.LogicalOperator.logical_invalid;
  }

  /**
   * Get literal type corresponding to the token
   * @param tokenCode token code
   * @param tokenType token type
   * @return literal type
   */
  function getLiteralValueType(uint tokenCode, IJSLexer.TokenType tokenType) internal pure returns (IAstBuilder.LiteralValueType) {
    if (tokenType == IJSLexer.TokenType.number || tokenType == IJSLexer.TokenType.bigInt) {
      return IAstBuilder.LiteralValueType.literal_number;
    } else if (tokenType == IJSLexer.TokenType.str) {
      return IAstBuilder.LiteralValueType.literal_string;
    } else if (tokenType == IJSLexer.TokenType.numberStr) {
      return IAstBuilder.LiteralValueType.literal_numberString;
    } else if (tokenType == IJSLexer.TokenType.regex) {
      return IAstBuilder.LiteralValueType.literal_regex;
    } else if (tokenType == IJSLexer.TokenType.keyword) {
      if (tokenCode == uint(IJSKeywordLexer.KeywordCode._true) || tokenCode == uint(IJSKeywordLexer.KeywordCode._false)) {
        return IAstBuilder.LiteralValueType.literal_boolean;
      } else if (tokenCode == uint(IJSKeywordLexer.KeywordCode._null)) {
        return IAstBuilder.LiteralValueType.literal_null;
      } else if (tokenCode == uint(IJSKeywordLexer.KeywordCode._undefined)) {
        return IAstBuilder.LiteralValueType.literal_undefined;
      }
    } else if (tokenType == IJSLexer.TokenType.punctuation) {
      if (tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftSquareBracket)) {
        return IAstBuilder.LiteralValueType.literal_array;
      } else if (tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftCurlyBrace)) {
        return IAstBuilder.LiteralValueType.literal_object;
      }
    }
    return IAstBuilder.LiteralValueType.literal_invalid;
  }
}