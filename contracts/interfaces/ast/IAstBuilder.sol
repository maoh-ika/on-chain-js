// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../lexer/IJSLexer.sol';

/**
 * The interface to build abstract syntax tree.
 */
interface IAstBuilder {
  enum NodeType {
    invalid,
    program, 
    identifier, 
    literal, 
    functionDeclaration, 
    variableDeclaration, 
    variableDeclarator, 
    expressionStatement, 
    returnStatement, 
    breakStatement, 
    continueStatement,
    blockStatement,
    ifStatement,
    whileStatement,
    forStatement,
    forInStatement,
    unaryExpression,
    binaryExpression,
    logicalExpression,
    assignmentExpression,
    updateExpression,
    memberExpression,
    objectExpression,
    callExpression,
    assignmentPattern,
    property,
    nullNode
  }

  struct AstNode {
    NodeType nodeType;
    uint nodeId;
    // additional data for identifying subtypes of node type.
    uint nodeDescriptor;
    /*
      abi encoded value data. The included data is as follows according to the node type.
      To decode literal type nodes, use decoder methods of AstNodeValueUtil. For other node types
      the value are not encoded in complicated format, so decode by using abi.decode simply. 

      identifier node =>
        name(string): identifier name
      string literal node =>
        value(string): string value
      number string literal node =>
        integer(uint): integer part of the number
        decimal(uint): decimal part of the number
        decimalDigits(uint): digits of decimal part
        expoenent(uint): exponent value of the number
        sign(bool): sign of the number. true if plus
        expSign(bool): sign of the exponent value. true if plus
        value(string): number value as string
      number literal node =>
        integer(uint): integer part of the number
        decimal(uint): decimal part of the number
        decimalDigits(uint): digits of decimal part
        expoenent(uint): exponent value of the number
        sign(bool): sign of the number. true if plus
        expSign(bool): sign of the exponent value. true if plus
      bool literal node =>
        value(boolean): bool value
      regex literal node =>
        regexPattern(string): regex pattern expression
        regexFlags(string): regex flags
    */
    bytes value;
    // node id array of child nodes 
    uint[] nodeArray;
  }
  
  // Runtime context
  struct Context {
    // current position in tokens array
    uint currentTokenIndex;
    // valid node count in nodes array
    uint nodeCount;
    // max node id in nodes array
    uint maxNodeId;
    // expression node count in nodes array. It is used for optimization in later intepretation process.
    uint expCount;
    // built ast nodes. the array index is the same as node id of the node at that position
    AstNode[] nodes;
  }

  enum UnaryOperator {
    unary_invalid, // 0
    unary_minus, // 1
    unary_plus, // 2
    unary_logicalNot, // 3
    unary_bitwiseNot, // 4
    unary_typeof, // 5
    unary_void, // 6
    unary_delete // 7
  }

  enum BinaryOperator {
    biop_invalid, // = 0,
    biop_in, // = 1,
    biop_instanceof, // = 2,
    biop_equality, // = 3,
    biop_inequality, // = 4,
    biop_strictEquality, // = 5,
    biop_strictInequality, // = 6,
    biop_lessThan, // = 7,
    biop_lessThanOrEqual, // = 8,
    biop_greaterThan, // = 9,
    biop_greaterThanOrEqual, // = 10,
    biop_leftShift, // = 11,
    biop_rightShift, // = 12,
    biop_unsignedRightShift, // = 13,
    biop_addition, // = 14,
    biop_subtraction, // = 15,
    biop_multiplication, // = 16,
    biop_division, // = 17,
    biop_remainder, // = 18,
    biop_bitwiseOr, // = 19,
    biop_bitwiseXor, // = 20,
    biop_bitwiseAnd // = 21,
  }

  enum LogicalOperator {
    logical_invalid, // 0
    logical_and, // 1
    logical_or // 2
  }

  enum UpdateOperator {
    update_invalid,
    update_increment,
    update_decrement
  }

  enum AssignmentOperator {
    invalid, // 0
    assignment, // 1
    additionAssignment, // 2
    subtractionAssignment, // 3
    exponentiationAssignment, // 4
    divisionAssignment, // 5
    remainderAssignment, // 6
    leftShiftAssignment, // 7
    rightShiftAssignment, // 8
    bitwiseOrAssignment, // 9
    bitwiseXorAssignment, // 10
    bitwiseAndAssignment // 11
  }
  
  enum LiteralValueType {
    literal_invalid,
    literal_string,
    literal_numberString,
    literal_boolean,
    literal_number,
    literal_regex,
    literal_array,
    literal_object,
    literal_null,
    literal_undefined
  }

  struct Ast {
    // all nodes
    AstNode[] nodes;
    // root node
    AstNode programNode;
    // count of the expression nodes
    uint expCount;
  }

  /**
   * Build abstract syntax tree
   * @param tokens tokenized source code
   * @return ast
   */
  function build(IJSLexer.Token[] calldata tokens) external view returns (Ast memory);
}