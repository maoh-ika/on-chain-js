// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../utils/Log.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interfaces/interpreter/IVisitor.sol';
import '../ast/AstNodeValueUtil.sol';
import './StringUtil.sol';
import './StateUtil.sol';
import './JSValueUtil.sol';
import './JSObjectImpl.sol';

/**
 * access control for implementation update
 */
contract JSInterpreterAdmin is Ownable {
  // address with permission to update state
  address public admin;
  // visitor interface
  IVisitor public visitor;

  constructor(IVisitor _visitor) {
    admin = owner();
    visitor = _visitor;
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
   * Update visitor implementation
   */
  function setVisitor(IVisitor _visitor) external onlyAdmin {
    visitor = _visitor;
  }
}

/**
 * Interpret and execute javascript code.
 */
contract JSInterpreter is JSInterpreterAdmin, IJSInterpreter {
  using StringUtil for string;
  using JSValueUtil for IJSInterpreter.JSValue;
  using JSObjectPropertyUtil for IJSInterpreter.JSObjectProperty;
  using StateUtil for IJSInterpreter.State;
  using AstNodeValueUtil for IAstBuilder.AstNode;

  enum FlowControl {
    _none,
    _break,
    _continue,
    _return
  }
  
  constructor(IVisitor _visitor) JSInterpreterAdmin(_visitor) {}
  
  /**
   * Interpret and execute abstract syntax tree.
   * @param ast abstract syntax tree
   * @return result
   */
  function interpret(IAstBuilder.Ast calldata ast) external view override returns (JSValue memory) {
    // console.log('IN interpretWithState');
    IJSInterpreter.State memory state;
    state.identifierStates = new IdentifierState[](1); // 0 is reserved
    IJSInterpreter.JSValue[] memory args;
    return _interpret(ast, state, args, 0);
  }
  
  /**
   * Interpret and execute abstract syntax tree with initial state such as arguments.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return result
   */
  function interpret(IAstBuilder.Ast calldata ast, InitialState calldata initialState) external view override returns (JSValue memory) {
    (JSValue memory value,) =  _interpret(ast, initialState, false);
    return value;
  }
  
  /**
   * Interpret and execute abstract syntax tree. Returns result as string.
   * @param ast abstract syntax tree
   * @return result
   */
  function interpretToString(IAstBuilder.Ast calldata ast) external view override returns (string memory) {
    IJSInterpreter.State memory state;
    state.identifierStates = new IdentifierState[](1); // 0 is reserved
    IJSInterpreter.JSValue[] memory args;
    return JSValueUtil.toStringValue(_interpret(ast, state, args, 0), state, true);
  }
  
  /**
   * Interpret and execute abstract syntax tree with initial state such as arguments.
   * Returns result as string.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return result
   */
  function interpretToString(IAstBuilder.Ast calldata ast, InitialState calldata initialState) external view override returns (string memory) {
    (JSValue memory value, IJSInterpreter.State memory state) = _interpret(ast, initialState, false);
    return JSValueUtil.toStringValue(value, state, true);
  }
  
  /**
   * Track dependencies dynamically while executing the code.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return dependencies
   */
  function traceDependencies(IAstBuilder.Ast calldata ast, InitialState calldata initialState) external view returns (Dependencies memory) {
    (, IJSInterpreter.State memory state) = _interpret(ast, initialState, true);
    address[] memory contractAddrs = new address[](state.contractDependees.length);
    for (uint i = 0; i < contractAddrs.length; ++i) {
      contractAddrs[i] = address(uint160(state.contractDependees[i]));
    }
    return Dependencies({
      contractDependees: contractAddrs,
      exeTokenDependees: state.exeTokenDependees
    });
  }
  
  /**
   * interpret and execute astract syntax tree. init runtime state with initialState.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return value result
   */
  function _interpret(
    IAstBuilder.Ast calldata ast,
    InitialState calldata initialState,
    bool needTraceDependencies
  ) private view returns (JSValue memory value, IJSInterpreter.State memory state) {
    state.identifierStates = new IdentifierState[](initialState.identifiers.length + 1); // 0 is reserved
    for (uint i = 0; i < initialState.identifiers.length; ++i) {
      uint index = i + 1;
      state.identifierStates[index].name = initialState.identifiers[i].name;
      bytes memory nameBytes = bytes(initialState.identifiers[i].name);
      bytes32 nameHash;
      assembly {
        nameHash := keccak256(add(nameBytes, 0x20), mload(nameBytes))
      }
      state.identifierStates[index].hash = nameHash;
      state.identifierStates[index].value = initialState.identifiers[i].value;
      state.identifierStates[index].value.identifierIndex = index;
    }
    state.traceDependencies = needTraceDependencies;
    return (_interpret(ast, state, initialState.args, initialState.startNodeIndex), state);
  }
  
  /**
   * interpret and execute function declaration node
   * @param ast abstract syntax tree
   * @param args arguments for function declaration
   * @return value result value
   */
  function _interpret(
    IAstBuilder.Ast calldata ast,
    IJSInterpreter.State memory state,
    IJSInterpreter.JSValue[] memory args,
    uint startNodeIndex
  ) private view returns (JSValue memory value) {
    if (startNodeIndex == 0) {
      for (uint i = 0; i < ast.programNode.nodeArray.length; ++i) {
        IAstBuilder.AstNode calldata node = ast.nodes[ast.programNode.nodeArray[i]];
        if (node.nodeType == IAstBuilder.NodeType.functionDeclaration) {
          value = _interpretFunctionDeclaration(node, ast.nodes, state, args);
          //console.log('[Result value]');
          //Log.logJSValue(value);
          return value;
        }
      }
    } else {
      IAstBuilder.AstNode calldata node = ast.nodes[startNodeIndex];
      if (node.nodeType == IAstBuilder.NodeType.functionDeclaration) {
        return _interpretFunctionDeclaration(node, ast.nodes, state, args);
      }
    }
    value.valueType = IJSInterpreter.JSValueType.value_undefined;
    return value;
  }

  /**
   * interpret function declaration node
   * @param funcDeclNode function declaration node
   * @param nodes ast nodes
   * @param state runtime state
   * @param args arguments for function declaration
   * @return result value
   */
  function _interpretFunctionDeclaration(
    IAstBuilder.AstNode calldata funcDeclNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state,
    IJSInterpreter.JSValue[] memory args
  ) private view returns (JSValue memory) {
    // console.log('IN _interpretFunctionDeclaration');
    IAstBuilder.AstNode calldata nameNode = nodes[funcDeclNode.nodeArray[0]];
    state.setDeclaredFunction(abi.decode(nameNode.value, (string)), funcDeclNode.nodeId);

    // the number of arguments the function can receives
    uint paramCount = funcDeclNode.nodeArray.length - 2;
    // the number of arguments received
    uint argCount = args.length;
    for (uint i = 0; i < paramCount; ++i) {
      IAstBuilder.AstNode calldata argNode = nodes[funcDeclNode.nodeArray[i + 1]];
      IdentifierState memory idState;
      uint identifierIndex;
      if (argNode.nodeType == IAstBuilder.NodeType.assignmentPattern) {
        // arg name and default value
        idState = _interpretIdentifier(nodes[argNode.nodeArray[0]], state);
        identifierIndex = idState.value.identifierIndex;
        idState.value = _interpretExpression(nodes[argNode.nodeArray[1]], nodes, state);
        state.updateIdentifierState(identifierIndex, idState.value);
      } else if (argNode.nodeType == IAstBuilder.NodeType.identifier) {
        // arg name only
        idState = _interpretIdentifier(argNode, state);
        identifierIndex = idState.value.identifierIndex;
      }
      // update with received arguments
      if (identifierIndex > 0 && i < argCount) {
        //Log.logJSValue(args[i]);
        state.updateIdentifierState(identifierIndex, args[i]);
      }
    }

    // body
    IAstBuilder.AstNode calldata bodyNode = nodes[funcDeclNode.nodeArray[funcDeclNode.nodeArray.length - 1]];
    (IJSInterpreter.JSValue memory result,) =  _interpretBlockStatement(bodyNode, nodes, state);
    return result;
  }

  /**
   * interpret statement type node
   * @param statNode statement node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   * @return flow control
   */
  function _interpretStatement(
    IAstBuilder.AstNode calldata statNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory, FlowControl) {
    // console.log('IN _interpretStatement');
    IJSInterpreter.JSValue memory invalid;
    if (statNode.nodeType == IAstBuilder.NodeType.variableDeclaration) {
      return (_interpretVariableDeclaration(statNode, nodes, state), FlowControl._none);
      // console.log('RESUME _interpretStatement');
    } else if (statNode.nodeType == IAstBuilder.NodeType.ifStatement) {
      return _interpretIfStatement(statNode, nodes, state);
    } else if (statNode.nodeType == IAstBuilder.NodeType.forStatement) {
      return _interpretForStatement(statNode, nodes, state);
    } else if (statNode.nodeType == IAstBuilder.NodeType.forInStatement) {
      return _interpretForInStatement(statNode, nodes, state);
    } else if (statNode.nodeType == IAstBuilder.NodeType.whileStatement) {
      return _interpretWhileStatement(statNode, nodes, state);
    } else if (statNode.nodeType == IAstBuilder.NodeType.blockStatement) {
      return _interpretBlockStatement(statNode, nodes, state);
    } else if (statNode.nodeType == IAstBuilder.NodeType.breakStatement) {
      return (invalid, FlowControl._break);
    } else if (statNode.nodeType == IAstBuilder.NodeType.continueStatement) {
      return (invalid, FlowControl._continue);
    } else if (
      statNode.nodeType == IAstBuilder.NodeType.expressionStatement ||
      statNode.nodeType == IAstBuilder.NodeType.updateExpression
    ) {
      JSValue memory result;
      result = _interpretExpression(nodes[statNode.nodeArray[0]], nodes, state);
      return (result, FlowControl._none);
    } else if (statNode.nodeType == IAstBuilder.NodeType.returnStatement) {
      JSValue memory result;
      result = _interpretExpression(nodes[statNode.nodeArray[0]], nodes, state);
      return (result, FlowControl._return);
    }
    // console.log('OUT _interpretStatement');
    return (invalid, FlowControl._none);
  }

  /**
   * interpret block statement node
   * @param blockNode block statement node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   * @return flow control
   */
  function _interpretBlockStatement(
    IAstBuilder.AstNode calldata blockNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory, FlowControl) {
    // console.log('IN _interpretBlockStatement');
    for (uint i = 0; i < blockNode.nodeArray.length; ++i) {
      IAstBuilder.AstNode calldata statNode = nodes[blockNode.nodeArray[i]];
      JSInterpreter.JSValue memory value;
      FlowControl flowControl;
      (value, flowControl) = _interpretStatement(statNode, nodes, state);
      // console.log('RESUME _interpretBlockStatement');
      if (flowControl != FlowControl._none) {
        return (value, flowControl); // exit this block
      }
    }  
    // console.log('IN _interpretBlockStatement');
    IJSInterpreter.JSValue memory undefined;
    undefined.valueType = IJSInterpreter.JSValueType.value_undefined;
    return (undefined, FlowControl._none);
  }

  /**
   * interpret variable declaration node
   * @param varDeclNode variable declaration node
   * @param nodes ast nodes
   * @param state runtime state
   * @return lastValue last declaration value
   */
  function _interpretVariableDeclaration(
    IAstBuilder.AstNode calldata varDeclNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (IJSInterpreter.JSValue memory lastValue) {
    // console.log('IN _interpretVariableDeclaration');
    // declarations
    for (uint i = 0; i < varDeclNode.nodeArray.length; ++i) {
      // id
      IAstBuilder.AstNode calldata declaratorNode = nodes[varDeclNode.nodeArray[i]];
      IdentifierState memory idState = _interpretIdentifier(nodes[declaratorNode.nodeArray[0]], state);
      // console.log('RESUME _interpretVariableDeclaration');
      // init
      if (nodes[declaratorNode.nodeArray[1]].nodeType != IAstBuilder.NodeType.nullNode) {
        uint identifierIndex = idState.value.identifierIndex;
        idState.value = _interpretExpression(nodes[declaratorNode.nodeArray[1]], nodes, state);
        state.updateIdentifierState(identifierIndex, idState.value);
        // console.log('RESUME _interpretVariableDeclaration2');
      }
      lastValue = idState.value;
    }
    // console.log('OUT _interpretVariableDeclaration');
  }
  
  /**
   * interpret if statement node
   * @param ifNode if statement node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   * @return flow control
   */
  function _interpretIfStatement(
    IAstBuilder.AstNode calldata ifNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory, FlowControl) {
    // console.log('IN _interpretIfStatement');
    // test
    IAstBuilder.AstNode calldata testNode = nodes[ifNode.nodeArray[0]];
    JSValue memory testResult;
    testResult = _interpretExpression(testNode, nodes, state);
    if (testResult.isTrue()) {
      IAstBuilder.AstNode calldata consequentNode = nodes[ifNode.nodeArray[1]];
      return _interpretStatement(consequentNode, nodes, state);
    } else {
      if (ifNode.nodeArray.length >= 3) {
        IAstBuilder.AstNode calldata altNode = nodes[ifNode.nodeArray[2]];
        return _interpretStatement(altNode, nodes, state);
      }
    }
    IJSInterpreter.JSValue memory invalid;
    return (invalid, FlowControl._none);
  }
  
  /**
   * interpret for statement node
   * @param forNode for statement node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   * @return flow control
   */
  function _interpretForStatement(
    IAstBuilder.AstNode calldata forNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory, FlowControl) {
    // console.log('IN _interpretForStatement');

    // init
    IAstBuilder.AstNode calldata initNode = nodes[forNode.nodeArray[0]];
    if (initNode.nodeType != IAstBuilder.NodeType.nullNode) {
      _interpretStatement(initNode, nodes, state);
    }
    
    // test
    IAstBuilder.AstNode calldata testNode = nodes[forNode.nodeArray[1]];
    while (true) {
      if (testNode.nodeType != IAstBuilder.NodeType.nullNode) {
        JSValue memory testResult;
        testResult = _interpretExpression(testNode, nodes, state);
        if (testResult.numberValue() == 0) {
          break;
        }
      }
      IAstBuilder.AstNode calldata bodyNode = nodes[forNode.nodeArray[3]];
      JSValue memory bodyResult;
      FlowControl flowControl;
      (bodyResult, flowControl) = _interpretStatement(bodyNode, nodes, state);
      if (flowControl == FlowControl._return) {
        return (bodyResult, flowControl);
      } else if (flowControl == FlowControl._break) {
        return (bodyResult, FlowControl._none);
      } 
      // update
      IAstBuilder.AstNode calldata updateNode = nodes[forNode.nodeArray[2]];
      if (updateNode.nodeType != IAstBuilder.NodeType.nullNode) {
        _interpretExpression(updateNode, nodes, state);
      }
    }

    IJSInterpreter.JSValue memory invalid;
    return (invalid, FlowControl._none);
  }
  
  /**
   * interpret for-in statement node
   * @param forInNode for-in statement node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   * @return flow control
   */
  function _interpretForInStatement(
    IAstBuilder.AstNode calldata forInNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory, FlowControl) {
    // console.log('IN _interpretForStatement');

    // left
    (IJSInterpreter.JSValue memory leftValue,) =  _interpretStatement(nodes[forInNode.nodeArray[0]], nodes, state);

    // right
    IJSInterpreter.JSValue memory rightValue;
    rightValue = _interpretExpression(nodes[forInNode.nodeArray[1]], nodes, state);
    require(rightValue.valueType == IJSInterpreter.JSValueType.value_object, 'for..in requires object');

    IJSInterpreter.JSObject memory objectValue = rightValue.objectValue();
    IAstBuilder.AstNode calldata bodyNode = nodes[forInNode.nodeArray[2]];
    uint[] memory propIndexes = objectValue.properties[objectValue.rootPropertyIndex].objectPropertyIndexes();
    for (uint p = 0; p < propIndexes.length; ++p) {
      IJSInterpreter.JSValue memory key;
      key.valueType = IJSInterpreter.JSValueType.value_string;
      key.value = abi.encode(objectValue.properties[propIndexes[p]].key);
      state.updateIdentifierState(leftValue.identifierIndex, key);
      
      // body
      JSValue memory bodyResult;
      FlowControl flowControl;
      (bodyResult, flowControl) = _interpretStatement(bodyNode, nodes, state);
      if (flowControl == FlowControl._return) {
        return (bodyResult, flowControl);
      } else if (flowControl == FlowControl._break) {
        return (bodyResult, FlowControl._none);
      } 
    }
    
    IJSInterpreter.JSValue memory invalid;
    return (invalid, FlowControl._none);
  }
  
  /**
   * interpret while statement node
   * @param whileNode while statement node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   * @return flow control
   */
  function _interpretWhileStatement(
    IAstBuilder.AstNode calldata whileNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory, FlowControl) {
    // console.log('IN _interpretWhileStatement');

    // test
    IAstBuilder.AstNode calldata testNode = nodes[whileNode.nodeArray[0]];
    while (true) {
      if (testNode.nodeType != IAstBuilder.NodeType.nullNode) {
        JSValue memory testResult;
        testResult = _interpretExpression(testNode, nodes, state);
        if (testResult.numberValue() == 0) {
          break;
        }
      }
      IAstBuilder.AstNode calldata bodyNode = nodes[whileNode.nodeArray[1]];
      JSValue memory bodyResult;
      FlowControl flowControl;
      (bodyResult, flowControl) = _interpretStatement(bodyNode, nodes, state);
      if (flowControl == FlowControl._return) {
        return (bodyResult, flowControl);
      } else if (flowControl == FlowControl._break) {
        return (bodyResult, FlowControl._none);
      }
    }

    IJSInterpreter.JSValue memory invalid;
    return (invalid, FlowControl._none);
  }

  /**
   * interpret expression node
   * @param expressionNode expression node
   * @param nodes ast nodes
   * @param state runtime state
   * @return result value
   */
  function _interpretExpression(
    IAstBuilder.AstNode calldata expressionNode,
    IAstBuilder.AstNode[] calldata nodes,
    State memory state
  ) private view returns (JSValue memory) {
    // console.log('IN _interpretExpression');

    IJSInterpreter.JSValue memory value;
    IJSInterpreter.State memory newState;
    (value, newState) = visitor.visit(expressionNode.nodeId, nodes, state);
    state.identifierStates = newState.identifierStates;
    state.firstValueSrcNode = newState.firstValueSrcNode;
    if (state.traceDependencies) {
      state.contractDependees = newState.contractDependees;
      state.exeTokenDependees = newState.exeTokenDependees;
    }
    return value;
  }

  /**
   * interpret identifier node
   * @param idNode identifier node
   * @param state runtime state
   * @return identifier state
   */
  function _interpretIdentifier(
    IAstBuilder.AstNode calldata idNode,
    State memory state
  ) private pure returns (IdentifierState memory) {
    // console.log('IN _interpretIdentifier');
    string memory name = idNode.decodeLiteralString();
    for (uint i = 0; i < state.identifierStates.length; ++i) {
      if (state.identifierStates[i].name.equal(name)) {
        return state.identifierStates[i];
      }
    }
    IJSInterpreter.JSValue memory undefined;
    undefined.valueType = IJSInterpreter.JSValueType.value_undefined;
    return state.setIdentifierState(name, undefined);
  }
}