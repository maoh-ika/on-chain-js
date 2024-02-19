// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../interfaces/snippetjs/ISnippetJS.sol';
import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import { AstNodeValueUtil } from '../ast/AstNodeValueUtil.sol';
import '../interpreter/StringUtil.sol';
import '../interpreter/NumberUtil.sol';

/**
 * access control for implementations update.
 */
contract SnippetJSAdmin is OwnableUpgradeable {
  address public admin;
  
  IJSLexer public lexer;
  IAstBuilder public astBuilder;
  IJSInterpreter public interpreter;

  function initialize(
    IJSLexer _lexer,
    IAstBuilder _astBuilder,
    IJSInterpreter _interpreter
  ) external initializer {
    lexer = _lexer;
    astBuilder = _astBuilder;
    interpreter = _interpreter;
    __Ownable_init();
    admin = owner();
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
   * Update lexer implementation
   */
  function setLexer(IJSLexer _lexer) external onlyAdmin {
    lexer = _lexer;
  }

  /**
   * Update ast builder implementation
   */
  function setAstBuilder(IAstBuilder _astBuilder) external onlyAdmin {
    astBuilder = _astBuilder;
  }

  /**
   * Update ast interpreter implementation
   */
  function setInterpreter(IJSInterpreter _interpreter) external onlyAdmin {
    interpreter = _interpreter;
  }
}

/**
 * The interface of SnippetJS
 */
contract SnippetJS is SnippetJSAdmin, ISnippetJS {
  /**
   * Execute javascript function code.
   * @param code function code
   * @return result
   */
  function interpret(string calldata code) external view override returns (IJSInterpreter.JSValue memory) {
    IJSLexer.Config memory config = IJSLexer.Config(true);
    IJSLexer.Token[] memory tokens = lexer.tokenize(code, config);
    IAstBuilder.Ast memory ast = astBuilder.build(tokens);
    return interpreter.interpret(ast);
  }
  
  /**
   * Execute javascript function code with initial state such as arguments.
   * @param code function code
   * @param initialState initial state
   * @return result
   */
  function interpretWithState(string calldata code, IJSInterpreter.InitialState calldata initialState) external view override returns (IJSInterpreter.JSValue memory) {
    IJSLexer.Config memory config = IJSLexer.Config(true);
    IJSLexer.Token[] memory tokens = lexer.tokenize(code, config);
    IAstBuilder.Ast memory ast = astBuilder.build(tokens);
    return interpreter.interpret(ast, initialState);
  }
  
  /**
   * Execute javascript function code. Returns result as string.
   * @param code function code
   * @return result
   */
  function interpretToString(string calldata code) external view override returns (string memory) {
    IJSLexer.Config memory config = IJSLexer.Config(true);
    IJSLexer.Token[] memory tokens = lexer.tokenize(code, config);
    IAstBuilder.Ast memory ast = astBuilder.build(tokens);
    return interpreter.interpretToString(ast);
  }
  
  /**
   * Execute javascript function code with initial state such as arguments.
   * Returns result as string.
   * @param code function code
   * @param initialState initial state
   * @return result
   */
  function interpretWithStateToString(string calldata code, IJSInterpreter.InitialState calldata initialState) external view override returns (string memory) {
    IJSLexer.Config memory config = IJSLexer.Config(true);
    IJSLexer.Token[] memory tokens = lexer.tokenize(code, config);
    IAstBuilder.Ast memory ast = astBuilder.build(tokens);
    return interpreter.interpretToString(ast, initialState);
  }

  /**
   * Tokenize javascript function code.
   * @param code function code
   * @param config tokenization configuration
   * @return tokens
   */
  function tokenize(string calldata code, IJSLexer.Config calldata config) external view override returns (IJSLexer.Token[] memory) {
    return lexer.tokenize(code, config);
  }
  
  /**
   * Build AST from code tokens.
   * @param tokens code tokens
   * @return AST
   */
  function buildAst(IJSLexer.Token[] calldata tokens) external view override returns (IAstBuilder.Ast memory) {
    return astBuilder.build(tokens);
  }
  
  /**
   * Interpret and execute abstract syntax tree with initial state.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return result
   */
  function interpretAst(IAstBuilder.Ast calldata ast, IJSInterpreter.InitialState calldata initialState) external view override returns (IJSInterpreter.JSValue memory) {
    return interpreter.interpret(ast, initialState);
  }
  
  /**
   * Parse function signature
   * @param code function code
   * @return signature
   */
  function parseSignature(string calldata code) external view returns (Signature memory) {
    Signature memory signature;
    IJSLexer.Config memory config = IJSLexer.Config(true);
    IJSLexer.Token[] memory tokens = lexer.tokenize(code, config);
    IAstBuilder.Ast memory ast = astBuilder.build(tokens);
    for (uint i = 0; i < ast.programNode.nodeArray.length; ++i) {
      IAstBuilder.AstNode memory funcDeclNode = ast.nodes[ast.programNode.nodeArray[i]];
      if (funcDeclNode.nodeType == IAstBuilder.NodeType.functionDeclaration) {
        IAstBuilder.AstNode memory nameNode = ast.nodes[funcDeclNode.nodeArray[0]];
        signature.name = abi.decode(nameNode.value, (string));
        uint paramCount = funcDeclNode.nodeArray.length - 2;
        signature.args = new string[](paramCount);
        signature.types = new IJSInterpreter.JSValueType[](paramCount);
        for (uint p = 0; p < paramCount; ++p) {
          IAstBuilder.AstNode memory argNode = ast.nodes[funcDeclNode.nodeArray[p + 1]];
          if (argNode.nodeType == IAstBuilder.NodeType.assignmentPattern) {
            signature.args[p] = abi.decode(ast.nodes[argNode.nodeArray[0]].value, (string));
            uint valueType = ast.nodes[argNode.nodeArray[1]].nodeDescriptor;
            signature.types[p] = IJSInterpreter.JSValueType(valueType);
          } else if (argNode.nodeType == IAstBuilder.NodeType.identifier) {
            signature.args[p] = abi.decode(argNode.value, (string));
          }
        }
        break;
      }
    }
    return signature;
  }
  
  /**
   * Track dependencies dynamically while executing the code.
   * @param code source code
   * @param initialState initial state
   * @return dependencies
   */
  function traceDependencies(string calldata code, IJSInterpreter.InitialState calldata initialState) external view returns (IJSInterpreter.Dependencies memory dependencies) {
    IJSLexer.Config memory config = IJSLexer.Config(true);
    IJSLexer.Token[] memory tokens = lexer.tokenize(code, config);
    IAstBuilder.Ast memory ast = astBuilder.build(tokens);
    bool needDynamicTrace = false;
    uint[] memory contractAddressValues;

    for (uint i = 0; i < ast.nodes.length; ++i) {
      IAstBuilder.AstNode memory node = ast.nodes[i];
      if (node.nodeType == IAstBuilder.NodeType.callExpression) {
        IAstBuilder.AstNode memory calleeNode = ast.nodes[node.nodeArray[0]];
        string memory funcName = AstNodeValueUtil.decodeLiteralString(calleeNode);
        if (StringUtil.equal(funcName, 'executeToken')) {
          // the first argument should be token id.
          IAstBuilder.AstNode memory idNode = ast.nodes[node.nodeArray[1]];
          if (
            idNode.nodeType == IAstBuilder.NodeType.literal &&
            idNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_number)
          ) {
            (uint id,,,,,) = AstNodeValueUtil.decodeLiteralNumber(idNode);
            if (!NumberUtil.exist(dependencies.exeTokenDependees, id)) {
              dependencies.exeTokenDependees = NumberUtil.addValue(dependencies.exeTokenDependees, id);
            }
          } else {
            needDynamicTrace = true;
          }
        } else if (StringUtil.equal(funcName, 'staticcallContract')) {
          // the first argument should be contract address.
          IAstBuilder.AstNode memory addrNode = ast.nodes[node.nodeArray[1]];
          if (
            addrNode.nodeType == IAstBuilder.NodeType.literal &&
            addrNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_numberString)
          ) {
            (uint addrValue,,,,,,) = AstNodeValueUtil.decodeLiteralNumberString(addrNode);
            if (!NumberUtil.exist(contractAddressValues, addrValue)) {
              contractAddressValues = NumberUtil.addValue(contractAddressValues, addrValue);
            }
          } else {
            needDynamicTrace = true;
          }
        }
      } 
    }
    if (needDynamicTrace) {
      IJSInterpreter.Dependencies memory dyDependencies = interpreter.traceDependencies(ast, initialState);
      for (uint i = 0; i < dyDependencies.contractDependees.length; ++i) {
        uint addrValue = uint(uint160(dyDependencies.contractDependees[i]));
        if (!NumberUtil.exist(contractAddressValues, addrValue)) {
          contractAddressValues = NumberUtil.addValue(contractAddressValues, addrValue);
        }
      }
      for (uint i = 0; i < dyDependencies.exeTokenDependees.length; ++i) {
        if (!NumberUtil.exist(dependencies.exeTokenDependees, dyDependencies.exeTokenDependees[i])) {
          dependencies.exeTokenDependees = NumberUtil.addValue(dependencies.exeTokenDependees, dyDependencies.exeTokenDependees[i]);
        }
      }
    }
    dependencies.contractDependees = new address[](contractAddressValues.length);
    for (uint i = 0; i < contractAddressValues.length; ++i) {
      dependencies.contractDependees[i] = address(uint160(contractAddressValues[i]));
    }
  }
}