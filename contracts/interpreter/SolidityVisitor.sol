// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../utils/Log.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interfaces/interpreter/IVisitor.sol';
import '../interfaces/interpreter/IGlobalFunction.sol';
import '../ast/AstNodeValueUtil.sol';
import './StringUtil.sol';
import './StateUtil.sol';
import './JSValueUtil.sol';
import './JSValueOp.sol';
import './JSArrayImpl.sol';
import './JSObjectImpl.sol';
import './JSLiteralUtil.sol';

/**
 * access control for implementation update
 */
contract SolidityVisitorAdmin is Ownable {
  // address with permission to update state
  address public admin;
  // global function interface
  IGlobalFunction public globalFunction;
  // interpreter interface
  IJSInterpreter public interpreter;

  constructor(IGlobalFunction _globalFunction, IJSInterpreter _interpreter) {
    admin = owner();
    globalFunction = _globalFunction;
    interpreter = _interpreter;
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
   * Update global function implementation
   */
  function setGlobalFunction(IGlobalFunction _globalFunction) external onlyAdmin {
    globalFunction = _globalFunction;
  }
  
  /**
   * Update interpreter implementation
   */
  function setInterpreter(IJSInterpreter _interpreter) external onlyAdmin {
    interpreter = _interpreter;
  }
}

/**
 * Interpret the AST into Solidity instructions and execute them.
 */
contract SolidityVisitor is SolidityVisitorAdmin, IVisitor {
  using StateUtil for IJSInterpreter.State;
  using JSObjectImpl for IJSInterpreter.JSObject;
  using JSArrayImpl for IJSInterpreter.JSArray;
  using JSValueUtil for IJSInterpreter.JSValue;
  using JSValueOp for IJSInterpreter.JSValue;
  using AstNodeValueUtil for IAstBuilder.AstNode;

  constructor(IGlobalFunction _globalFunction, IJSInterpreter _interpreter) SolidityVisitorAdmin(_globalFunction, _interpreter) {}

  /**
   * Visit and evaluate a ast node
   * @param nodeIndex the index of nodes, which refer to the ast node to visit
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   * @return updated state
   * @notice The state argument is received as 'memory' because it may be updated.
   *         This function is executed in different environment and memory addresses from caller, so we need passing
   *         the updated state to caller as return value which is passed as copy.
   */
  function visit(
    uint nodeIndex,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) external view override returns (IJSInterpreter.JSValue memory, IJSInterpreter.State memory) {
    return (_visit(nodeIndex, nodes, state), state);
  }
  
  /**
   * Implementation of visit
   * @param nodeIndex the index of nodes, which refer to the ast node to visit
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   */
  function _visit(
    uint nodeIndex,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory) {
    IAstBuilder.AstNode calldata node = nodes[nodeIndex];
    //console.log('IN visit');
    // Log.logAstNode(node);
    if (node.nodeType == IAstBuilder.NodeType.unaryExpression) {
      // console.log('IN visitUnaryOperation');
      return _visitUnaryOperation(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.binaryExpression) {
      // console.log('IN visitBinaryOperation');
      return _visitBinaryOperation(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.assignmentExpression) {
      // console.log('IN visitAssignmentOperation');
      return _visitAssignmentOperation(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.updateExpression) {
      // console.log('IN visitUpdateOperation');
      return _visitUpdateOperation(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.logicalExpression) {
      // console.log('IN visitLogicalOperation');
      return _visitLogicalOperation(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.memberExpression) {
      // console.log('IN visitMemberExpression');
      if (state.firstValueSrcNode == 0) {
        state.firstValueSrcNode = node.nodeId;
      }
      return _visitMemberExpression(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.objectExpression) {
      // console.log('IN visitObject');
      return _visitObject(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.callExpression) {
      // console.log('IN visitCall');
      return _visitCallExpression(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.literal) {
      return _visitLiteral(node, nodes, state);
    } else if (node.nodeType == IAstBuilder.NodeType.identifier) {
      // console.log('IN visitIdentifier');
      if (state.firstValueSrcNode == 0) {
        state.firstValueSrcNode = node.nodeId;
      }
      IJSInterpreter.IdentifierState memory idState = state.getIdentifierState(node.decodeLiteralString());
      if (idState.value.identifierIndex == 0) {
        revert('undefined identifier');
      }
      return idState.value;
    } else {
      revert();
    }
  }
  
  /**
   * Interpret member expression node
   * @param memberNode member expression node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return res result value
   */
  function _visitMemberExpression(
    IAstBuilder.AstNode calldata memberNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory res) {
    IJSInterpreter.JSValue memory objectValue = _visit(memberNode.nodeArray[0], nodes, state);
    IJSInterpreter.JSValue memory propertyValue;
    if (memberNode.decodeLiteralBoolean()) { // computed
      propertyValue = _visit(memberNode.nodeArray[1], nodes, state);
    } else { // identifier or literal
      propertyValue.valueType = IJSInterpreter.JSValueType.value_string;
      propertyValue.value = abi.encode(nodes[memberNode.nodeArray[1]].decodeLiteralString());
    }
    if (objectValue.valueType == IJSInterpreter.JSValueType.value_reference) {
      objectValue = objectValue.resolveReference(state);
    }
    if (objectValue.valueType == IJSInterpreter.JSValueType.value_array) {
      if (propertyValue.valueType == IJSInterpreter.JSValueType.value_number) {
        require(propertyValue.numberSign, 'out of range');
        res = objectValue.arrayValue().at(JSValueUtil.toRaw(propertyValue.numberValue()));
      } else {
        res = objectValue.arrayValue().property(propertyValue.stringValue());
      }
    } else if (objectValue.valueType == IJSInterpreter.JSValueType.value_object) {
      string memory key;
      if (propertyValue.identifierIndex == 0) { // undefined identifier
        key = propertyValue.stringValue(); // identifier name
      } else {
        key = JSValueUtil.toStringLiteral(propertyValue, true);
      }
      res = objectValue.objectValue().getValue(key);
    } else {
      revert('invalid access');
    }
    if (res.identifierIndex == 0) {
      res.identifierIndex = objectValue.identifierIndex;
    }
  }
  
  /**
   * Interpret literal value node
   * @param literalNode literal value node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return res result value
   */
  function _visitLiteral(
    IAstBuilder.AstNode calldata literalNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory jsValue;
    if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_array)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_array;
      IJSInterpreter.JSArray memory arrayValue;
      _makeArrayValue(literalNode, nodes, state, arrayValue, 0);
      jsValue.value = abi.encode(arrayValue);
    } else {
      jsValue = JSLiteralUtil.makeLiteralValue(literalNode);
    }

    return jsValue;
  }
  
  /**
   * Interpret object literal node
   * @param objectNode object literal node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   */
  function _visitObject(
    IAstBuilder.AstNode calldata objectNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory jsValue;
    jsValue.valueType = IJSInterpreter.JSValueType.value_object;
    IJSInterpreter.JSObject memory objectValue = JSObjectImpl.newObject();

    for (uint i = 0; i < objectNode.nodeArray.length; ++i) {
      string memory key;
      IAstBuilder.AstNode calldata propNode = nodes[objectNode.nodeArray[i]];
      uint keyNodeIndex = propNode.nodeArray[0];
      IAstBuilder.AstNode calldata keyNode = nodes[keyNodeIndex];
      if (propNode.decodeLiteralBoolean()) { // computed
        IJSInterpreter.JSValue memory keyValue = _visit(keyNodeIndex, nodes, state);
        key = keyValue.stringValue();
      } else { // identifier or literal
        key = keyNode.decodeLiteralString();
      }
      IJSInterpreter.JSValue memory value = _visit(nodes[objectNode.nodeArray[i]].nodeArray[1], nodes, state);
      if (value.identifierIndex > 0 && value.isReferenceType()) {
        IJSInterpreter.JSValue memory refValue;
        refValue.valueType = IJSInterpreter.JSValueType.value_reference;
        refValue.value = abi.encode(value.identifierIndex);
        objectValue.set(key, refValue);
      } else {
        objectValue.set(key, value);
      }
    }
    jsValue.value = abi.encode(objectValue);
    return jsValue;
  }
  
  /**
   * Interpret call expression node
   * @param callNode call expression node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return res result value
   */
  function _visitCallExpression(
    IAstBuilder.AstNode calldata callNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory res) {
    IAstBuilder.AstNode memory calleeNode = nodes[callNode.nodeArray[0]];
    IJSInterpreter.JSValue[] memory argValues = new IJSInterpreter.JSValue[](callNode.nodeArray.length - 1);
    for (uint i = 1; i < callNode.nodeArray.length; ++i) {
      argValues[i - 1] = _visit(callNode.nodeArray[i], nodes, state);
    }
    if (calleeNode.nodeType == IAstBuilder.NodeType.identifier) { // global functions
      string memory funcName = calleeNode.decodeLiteralString();
      uint funcDeclNodeIndex = state.getDeclaredFunction(funcName);
      if (funcDeclNodeIndex > 0) {
        IJSInterpreter.InitialState memory initState;
        initState.args = argValues;
        initState.startNodeIndex = funcDeclNodeIndex;
        IAstBuilder.Ast memory ast;
        ast.nodes = nodes;
        res = interpreter.interpret(ast, initState);
      } else {
        uint[] memory contractDependees;
        uint[] memory exeTokenDependees;
        (res, contractDependees, exeTokenDependees) = globalFunction.call(funcName, argValues, state.traceDependencies);
        if (state.traceDependencies) {
          state.contractDependees = NumberUtil.concat(state.contractDependees, contractDependees);
          state.exeTokenDependees = NumberUtil.concat(state.exeTokenDependees, exeTokenDependees);
        }
      }
      return res;
    } else { // instance methods
      IJSInterpreter.JSValue memory calleeValue = _visit(calleeNode.nodeId, nodes, state);
      if (calleeValue.valueType == IJSInterpreter.JSValueType.value_function) {
        bytes memory funcDef = calleeValue.value;
        IJSInterpreter.JSValueType objectType;
        assembly { objectType := mload(add(funcDef, 32)) }
        if (objectType == IJSInterpreter.JSValueType.value_array) {
          (,IJSInterpreter.JSArray memory array, string memory funcName) = abi.decode(funcDef, (uint, IJSInterpreter.JSArray, string));
          res = array.method(funcName, argValues);
          IJSInterpreter.JSValue memory idValue = state.identifierStates[calleeValue.identifierIndex].value;
          IJSInterpreter.JSArray memory idArrayValue = idValue.arrayValue();
          idArrayValue.elements = array.elements;
          idValue.value = abi.encode(idArrayValue);
          state.updateIdentifierState(calleeValue.identifierIndex, idValue);
        }
      }
    }
  }
  
  /**
   * Interpret unary operator node
   * @param unaryNode unary operator node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   */
  function _visitUnaryOperation(
    IAstBuilder.AstNode calldata unaryNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory argValue = _visit(unaryNode.nodeArray[0], nodes, state);
    console.log('UNALRY %d', unaryNode.nodeDescriptor);
    return JSValueOp.unaryOperation(argValue, IAstBuilder.UnaryOperator(unaryNode.nodeDescriptor));
  }

  /**
   * Interpret binary operator node
   * @param binaryNode binary operator node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return res result value
   */
  function _visitBinaryOperation(
    IAstBuilder.AstNode calldata binaryNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory res) {
    IJSInterpreter.JSValue memory leftResult = _visit(binaryNode.nodeArray[0], nodes, state);
    IJSInterpreter.JSValue memory rightResult = _visit(binaryNode.nodeArray[1], nodes, state);
    return JSValueOp.binaryOperation(
      leftResult,
      rightResult,
      state,
      IAstBuilder.BinaryOperator(binaryNode.nodeDescriptor)
    );
  }
  
  /**
   * Interpret assignment operator node
   * @param assignmentNode assignment operator node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   */
  function _visitAssignmentOperation(
    IAstBuilder.AstNode calldata assignmentNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) public view returns (IJSInterpreter.JSValue memory) {
    uint leftNodeIndex = assignmentNode.nodeArray[0];
    IAstBuilder.AstNode calldata leftNode = nodes[leftNodeIndex];
    IJSInterpreter.JSValue memory leftResult = _visit(leftNodeIndex, nodes, state);
    IJSInterpreter.JSValue memory rightResult = _visit(assignmentNode.nodeArray[1], nodes, state);
    IJSInterpreter.JSValue memory result = JSValueOp.assignmentOperation(
      leftResult,
      rightResult,
      state,
      IAstBuilder.AssignmentOperator(assignmentNode.nodeDescriptor)
    );

    _updateIdentifierState(nodes, leftNode, state, result);
    return result;
  }
  
  /**
   * Interpret update operator node
   * @param updateNode update operator node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   */
  function _visitUpdateOperation(
    IAstBuilder.AstNode calldata updateNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory) {
    state.firstValueSrcNode = 0;
    IJSInterpreter.JSValue memory argValue = _visit(updateNode.nodeArray[0], nodes, state);
    IJSInterpreter.JSValue memory result = argValue;
    IJSInterpreter.JSValue memory newStateValue = result;
    bool isPrefix = updateNode.decodeLiteralBoolean();
    if (updateNode.nodeDescriptor == uint(IAstBuilder.UpdateOperator.update_increment)) {
      newStateValue = result.increment(state); 
      if (isPrefix) { // prefix
        result = result.increment(state); 
      }
    } else if (updateNode.nodeDescriptor == uint(IAstBuilder.UpdateOperator.update_decrement)) {
      newStateValue = result.decrement(state); 
      if (isPrefix) { // prefix
        result = result.decrement(state);
      }
    }

    _updateIdentifierState(nodes, nodes[state.firstValueSrcNode], state, newStateValue);
    return result;
  }
  
  /**
   * Interpret logical operator node
   * @param logicalNode logical operator node to interpret
   * @param nodes ast nodes
   * @param state interpretation state
   * @return res result value
   */
  function _visitLogicalOperation(
    IAstBuilder.AstNode calldata logicalNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) private view returns (IJSInterpreter.JSValue memory res) {
    IJSInterpreter.JSValue memory leftResult = _visit(logicalNode.nodeArray[0], nodes, state);
    if (logicalNode.nodeDescriptor == uint(IAstBuilder.LogicalOperator.logical_and)) {
      if (!leftResult.isTrue()) {
        return leftResult;
      } else {
        return _visit(logicalNode.nodeArray[1], nodes, state);
      }
    } else if (logicalNode.nodeDescriptor == uint(IAstBuilder.LogicalOperator.logical_or)) {
      if (leftResult.isTrue()) {
        return leftResult;
      }
      IJSInterpreter.JSValue memory rightValue = _visit(logicalNode.nodeArray[1], nodes, state);
      if (rightValue.isTrue()) {
        return rightValue;
      } else {
        res.valueType = IJSInterpreter.JSValueType.value_boolean;
        res.value = abi.encode(false);
        return res;
      }
    }
  }

  /**
   * update identifier state with new value
   * @param nodes ast nodes
   * @param idWrapperNode node representing the identifier
   * @param state interpretation state
   * @param value new value to tie the identifier
   */
  function _updateIdentifierState(
    IAstBuilder.AstNode[] calldata nodes,
    IAstBuilder.AstNode calldata idWrapperNode,
    IJSInterpreter.State memory state,
    IJSInterpreter.JSValue memory value
  ) public view {
    // console.log('IN _updateIdentifierState');
    IJSInterpreter.JSValue memory idValue;
    if (idWrapperNode.nodeType == IAstBuilder.NodeType.identifier) {
      // idWrapperNode is the identifier itself
      idValue = _visit(idWrapperNode.nodeId, nodes, state);
      value.identifierIndex = idValue.identifierIndex;
      idValue = value;
    } else if (idWrapperNode.nodeType == IAstBuilder.NodeType.memberExpression) {
      // evaluate member expression node and get the object to be dilectly updated with new value.
      IJSInterpreter.JSValue memory objectValue = _visit(idWrapperNode.nodeArray[0], nodes, state);
      if (objectValue.valueType == IJSInterpreter.JSValueType.value_reference) {
        objectValue = objectValue.resolveReference(state);
      }
      idValue = state.identifierStates[objectValue.identifierIndex].value;
      IJSInterpreter.JSValue memory propertyValue;
      if (idWrapperNode.decodeLiteralBoolean()) { // computed
        propertyValue = _visit(idWrapperNode.nodeArray[1], nodes, state);
      } else { // identifier or literal
        propertyValue.valueType = IJSInterpreter.JSValueType.value_string;
        propertyValue.value = abi.encode(nodes[idWrapperNode.nodeArray[1]].decodeLiteralString());
      }
      if (objectValue.valueType == IJSInterpreter.JSValueType.value_array) {
        // Due to implementation efficiency issue, there is a restriction that arrays in object cannot be updated.
        require(idValue.valueType == IJSInterpreter.JSValueType.value_array, 'arr in obj');
        require(propertyValue.numberSign, 'out of range');
        uint elemIndex = JSValueUtil.toRaw(propertyValue.numberValue());
        IJSInterpreter.JSArray memory arrayValue = objectValue.arrayValue();
        arrayValue.update(elemIndex, value);
        IJSInterpreter.JSArray memory idArrayValue = idValue.arrayValue();
        idArrayValue.elements = arrayValue.elements;
        idValue.value = abi.encode(idArrayValue);
      } else if (objectValue.valueType == IJSInterpreter.JSValueType.value_object) {
        // Due to implementation efficiency issue, there is a restriction that objects in array cannot be updated.
        require(idValue.valueType == IJSInterpreter.JSValueType.value_object, 'obj in arr');
        IJSInterpreter.JSObject memory object = objectValue.objectValue();
        object.set(propertyValue.stringValue(), value);
        IJSInterpreter.JSObject memory idObject = idValue.objectValue();
        idObject.properties = object.properties;
        idValue.value = abi.encode(idObject);
      }
    }
    state.updateIdentifierState(idValue.identifierIndex, idValue);
  }

  /**
   * Make array value from array literal node
   * @param literalNode array literal node
   * @param nodes ast nodes
   * @param state interpretation state
   * @param array JSArray
   * @param depth depth in nested array
   */
  function _makeArrayValue(
    IAstBuilder.AstNode calldata literalNode,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state,
    IJSInterpreter.JSArray memory array, 
    uint depth
  ) private view {
    // console.log('IN _makeArrayValue');
    IJSInterpreter.JSValue[] memory elems;
    array.push(elems); // make root elem;
    elems = new IJSInterpreter.JSValue[](literalNode.nodeArray.length);
    for (uint i = 0; i < literalNode.nodeArray.length; ++i) {
      IJSInterpreter.JSValue memory elem = elems[i];
      IAstBuilder.AstNode calldata elemNode = nodes[literalNode.nodeArray[i]];
      if (elemNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_array)) {
        // nested array
        elem.valueType = IJSInterpreter.JSValueType.value_array;
        IJSInterpreter.JSArray memory childArray;
        _makeArrayValue(elemNode, nodes, state, childArray, depth + 1);
        elem.value = abi.encode(childArray);
      } else if (elemNode.nodeType == IAstBuilder.NodeType.objectExpression) {
        IJSInterpreter.JSValue memory elemValue = _visitObject(elemNode, nodes, state);
        elem.value = elemValue.value;
        elem.valueType = elemValue.valueType;
      } else if (elemNode.nodeType == IAstBuilder.NodeType.identifier) {
        IJSInterpreter.IdentifierState memory id = state.getIdentifierState(elemNode.decodeLiteralString());
        if (id.value.isReferenceType()) {
          elem.valueType = IJSInterpreter.JSValueType.value_reference;
          elem.value = abi.encode(id.value.identifierIndex);
        } else {
          elem.value = id.value.value;
          elem.numberSign = id.value.numberSign;
          elem.valueType = id.value.valueType;
        }
      } else {
        IJSInterpreter.JSValue memory elemValue = _visitLiteral(elemNode, nodes, state);
        elem.value = elemValue.value;
        elem.numberSign = elemValue.numberSign;
        elem.valueType = elemValue.valueType;
      }
    }
    array.push(elems);
  }
}