// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../ast/IAstBuilder.sol';

/*
 * The interface to interpret javascript code.
 */
interface IJSInterpreter {

  enum JSValueType {
    value_invalid, // 0
    value_string, // 1
    value_numberString, // 2
    value_boolean, // 3
    value_number, // 4
    value_regex, // 5
    value_array, // 6
    value_object, // 7
    value_null, // 8
    value_undefined, // 9
    value_nan, // 10
    value_infinity, // 11
    value_bytes, // 12
    value_function, // 13
    value_reference // 14
  }

  struct JSArrayElement {
    /*
      abi encoded value data. The included data is as follows according to the value type.
        value_object: JSObject
        vaue_array: uint[]. array elements indexes which refer to elements in JSArray.elements
        others: value itself
    */
    bytes value;
    // sign of number like value
    bool numberSign;
    JSValueType valueType;
  }

  struct JSArray {
    /*
     elements of the array. Even in the case of nested arrays, all elements are
     managed in this one-dimensional array.  Nested arrays are represented by elements
     whose type is value_array, and its uint[] value ​​specify the elements in the array.
    */
    JSArrayElement[] elements;
    /*
      Index of element which refer to a JSArrayElement whose type is value_array.
      rootElementIndex also represents current dimension of JSArray. When move to nested
      child array, set rootElementIndex to the index of child JSArrayElement element.
    */ 
    uint rootElementIndex;
  }
  
  struct JSObjectProperty {
    /*
      abi encoded value data. The included data is as follows according to the value type.
        object: uint[]. object properties indexes which refer to elements in JSObject.properties
        array: JSArray
        others: value itself
    */
    bytes value;
    // property name
    string key;
    // hash of key
    bytes32 keyHash;
    // sign of number like value
    bool numberSign;
    JSValueType valueType;
  }

  struct JSObject {
    /*
     properties of the object. Even in the case of nested objects, all properties are
     managed in this one-dimensional array.  Nested objects are represented by elements
     whose type is value_object, and its uint[] value ​​specify the own properties in the properties array.
    */
    JSObjectProperty[] properties;
    /*
      Index of element which refer to a JSObjectProperty whose type is value_object.
      In the case of nested objects. rootPropertyIndex also represents current nest level.
      When move to nested child object, set rootPropertyIndex to the index of child JSObjectProperty element.
    */ 
    uint rootPropertyIndex;
  }

  struct JSValue {
    /*
      abi encoded value data. the included data is as follows according to the value type.
      object: JSObject
      array: JSArray
      others: value itself
    */
    bytes value;
    // Index of State.identifierStates. If the value is not registered in State, identifierIndex is 0.
    uint identifierIndex;
    // sign of number like value
    bool numberSign;
    JSValueType valueType;
  }

  struct IdentifierState {
    // identifier name
    string name;
    // hash of name
    bytes32 hash;
    // value tied to the name
    IJSInterpreter.JSValue value;
  }
  
  struct DeclaredFunction {
    // function name
    string name;
    // root node of function
    uint rootNodeIndex;
  }

  // interpretation state
  struct State {
    // current states of identifiers
    IdentifierState[] identifierStates;
    // Declared functions
    DeclaredFunction[] declaredFunctions;
    // id of the first node visited while traversing the tree of expressions that produce a value.
    uint firstValueSrcNode;
    // flag indicating dependecy tracing enabled
    bool traceDependencies;
    // external smart contract addresses the code depends on
    uint[] contractDependees;
    // external ExeToken ids the code depends on
    uint[] exeTokenDependees;
  }

  // identifier definition for InitialState
  struct Identifier {
    // identifier name
    string name;
    // value tied to the name
    IJSInterpreter.JSValue value;
  }

  // Initial state of interpretation
  struct InitialState {
    // pre defiened indentifiers
    Identifier[] identifiers;
    // arguments passed to the function being interpreted
    JSValue[] args;
    // node index to start interpreting
    uint startNodeIndex;
  }

  struct Dependencies {
    // external smart contract addresses the code depends on
    address[] contractDependees;
    // external ExeToken ids the code depends on
    uint[] exeTokenDependees;
  }

  /**
   * Interpret and execute abstract syntax tree.
   * @param ast abstract syntax tree
   * @return result
   */
  function interpret(IAstBuilder.Ast calldata ast) external view returns (JSValue memory);
  
  /**
   * Interpret and execute abstract syntax tree with initial state such as arguments.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return result
   */
  function interpret(IAstBuilder.Ast calldata ast, InitialState calldata initialState) external view returns (JSValue memory);
  
  /**
   * Interpret and execute abstract syntax tree. Returns result as string.
   * @param ast abstract syntax tree
   * @return result
   */
  function interpretToString(IAstBuilder.Ast calldata ast) external view returns (string memory);
  
  /**
   * Interpret and execute abstract syntax tree with initial state such as arguments.
   * Returns result as string.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return result
   */
  function interpretToString(IAstBuilder.Ast calldata ast, InitialState calldata initialState) external view returns (string memory);

  /**
   * Track dependencies dynamically while executing the code.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return dependencies
   */
  function traceDependencies(IAstBuilder.Ast calldata ast, InitialState calldata initialState) external view returns (Dependencies memory);
}