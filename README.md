# OnChainJS

OnChainJS is a on-chain JavaScript interpreter, specialized in executing functions.

It is written in Solidity and works as a smart contract on Ethereum. All of the functionalities
are constructed using only call functions and do not generate transactions, so you can use it without paying gas costs.

OnChainJS executes one JavaScript function code and returns the result value. By integrating with other smart contracts,
it can dynamically modify the behavior of the contract and easily develop lightweight dApps.

## Usage

An example to run using ethers.js.

```
import { ethers } from 'ethers';
import snippetJsAbi from '../artifacts/contracts/api/SnippetJS.sol/SnippetJS';

const proxyAddress = '0x87102b1B2cb75d50719F65a04C3C5D6A51d14aCf';
const snippetJs = new ethers.Contract(
  proxyAddress,
  snippetJsAbi.abi,
  ethers.provider
);

// function code to run
const code = 'function add(num1 = 1, num2 = 2) { return num1 + num2; }';

// run the function
const result = await snippetJs.interpretToString(code);

console.log(result);
```

The execution result is

```
3
```

An example to run from other contract.

```
// import ISnippetJS interface definition.
import { ISnippetJS } from './interfaces/api/ISnippetJS.sol';

contract Demo {
  function runJS() {
    ISnippetJS snippetJs = ISnippetJS('0x87102b1B2cb75d50719F65a04C3C5D6A51d14aCf');
    string memory code = 'function add(num1 = 1, num2 = 2) { return num1 + num2; }';
    string memory result = snippetJs.interpretString(code);
    console.log(result);
  }
}
```

## Contracts

Beta version is live on Goerli testnet.


| Contract                                                   | Description                                                                                                                                   | Address                                                                                                                                                                                                                |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [SnippetJSProxy](https://github.com/maoh-ika/on-chain-js/blob/main/contracts/snippetjs/SnippetJSProxy.sol)     | This is the interface contract for accessing functionalities exposed in the[ISnippetJS.sol](https://github.com/maoh-ika/on-chain-js/blob/main/contracts/interfaces/snippetjs/ISnippetJS.sol). | Goerli: 0x87102b1B2cb75d50719F65a04C3C5D6A51d14aCf                                                                                                                                                                     |
| [SnippetJS](https://github.com/maoh-ika/on-chain-js/blob/main/contracts/snippetjs/SnippetJS.sol)                 | This contract is the upgradeable implementation for SnippetJSProxy.                                                                           | Goerli: 0x9175bbea09F865CF034f6430bA4B80c9dDcCc8530xA28448c9f8eaFcf625A144601B7dF622C825dE5E0x87102b1B2cb75d50719F65a04C3C5D6A51d14a                                                                                   |
| [JSLexer](https://github.com/maoh-ika/on-chain-js/blob/main/contracts/lexer/JSLexer.sol)                   | This is the main contract for tokenizing source code.                                                                                         | Goerli: 0x3B3c1A2c079579f87Cb3fD2c854690b6E50ad5240x9B3355f1B99E6e4fF9bE8Be3A8CfF11fe494CB550xA28448c9f8eaFcf625A144601B7dF622C825dE5E0x87102b1B2cb75d50719F65a04C3C5D6A51d14                                          |
| [AstBuilder](https://github.com/maoh-ika/on-chain-js/blob/main/contracts/ast/AstBuilder.sol)               | This is the main contract for building the abstract syntax tree.                                                                              | Goerli: 0x4E3dccD1588BF0c633080bb0c608ECF28B8020B90x9B3355f1B99E6e4fF9bE8Be3A8CfF11fe494CB550xA28448c9f8eaFcf625A144601B7dF622C825dE5E0x87102b1B2cb75d50719F65a04C3C5D6A51d14                                          |
| [JSInterpreter](https://github.com/maoh-ika/on-chain-js/blob/main/contracts/interpreter/JSInterpreter.sol) | This contract interprets AST into Solidity instructions and executes them.                                                                    | Goerli: 0x11176c03Ae0dEe3A7198b7F5aF9eD31968e85f2E0xf12E26a0964D602949d4d29C3185Cd7CF4466E580x9B3355f1B99E6e4fF9bE8Be3A8CfF11fe494CB550xA28448c9f8eaFcf625A144601B7dF622C825dE5E0x87102b1B2cb75d50719F65a04C3C5D6A51d1 |

## Limitations

OnChainJS implements the minimal JavaScript specification subset required to execute a function. Therefore, there are the following limitations compared to the full spec JavaScript.

* The function code passed to OnChainJS must start with a function definition starting with the "function" keyword.
* Only one function can be run at a time.
* Only "var" can be used in variable declaration.
* No Class sysytem, and neither class-based nor prototype chain based inheritance is supported.
* The standard built-in functions and libraries are not implemented so far.

## Arguments

OnChainJS can tekes arguments at runtime. The type of the argument value is [JSValue](./contracts/interfaces/interpreter/IJSInterpreter.sol) struct. JSValue is the type that represents the types of JavaScript variable. Available types are listed on [IJSInterpreter.JSValueType](./contracts/interfaces/interpreter/IJSInterpreter.sol).
Here is an example of runnning a function with arguments.

```
// Solidity ABI encoder
const coder = ethers.utils.defaultAbiCoder;

const numArg = {
  valueType: 4, // number type
  value: coder.encode(['uint'], [123450000000000000000n]), // 18 digits fixed-point pdecimal.
  numberSign: true, // true: positive, false: negative
  identifierIndex: 0 // fixed to 0
}
const strArg = {
  valueType: 1, // string type
  value: coder.encode(['string'], [' ETH']), // encode into bytes
  numberSign: true,
  identifierIndex: 0 // fixed to 0
}

const initialState = {
  args: [numArg, strArg],
  identifiers: []
}

// run with 2 arguments
const code = 'function add(arg1, arg2) { return arg1 + arg2; }'
const result = await snippetJs.interpretWithStateToString(code, initialState)
console.log(result)
```

The result will be displayed as below.

```
123.45 ETH
```

SnippetsJS treats numbers in 18-digit fixed-point format. In the above example, the 18 digits to the right of numArg (450000000000000000) are the fractional part and the rest to the left (123) are the integer part.
Note that externally supplied number arguments are specified in this format.

## Default arguments

Function parameters can have default values. Default arguments are used if no actual arguments are given when the function is executed.

```
// function with two parameters and default values
const code = 'function add(arg1="Default", arg2="Value") { return arg1 + arg2; }'

// run with no actual arguments
const result = await snippetJs.interpretToString(code)
console.log(result)
```

The result will be displayed as below.

```
DefaultValue
```

## Call other contracts

OnChainJS has a built-in function for calling other contracts from your code, "staticcallContract" function. This function encodes the arguments passed to the contract as calldata, calls the contract, and decodes the return value for use in your code.
Here is an sample of using staticcallContract function.

```
const code = `
  function func() {
    var price = staticcallContract(
      '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', // contract address
      'concat(uint256,string)', // target method signature of the contract
      'string', // type of return value
      123, // value for first argument
      'ETH' // value for second argument
    );

    return 'current price is ' + price;
  }`

// run the code, call contract and receive the result of the call.
const result = await snippetJs.interpretToString(code)
console.log(result)
```

The result will be displayed as below.

```
current price is 123ETH
```

The first argument of staticcallContract is the address of the contract to call. The second argument is the method signature of the contract. The signature is according to [Solidity ABI specification](https://solidity-jp.readthedocs.io/ja/latest/abi-spec.html). The third argument is the type of the result. It accepts a the type name or a ABI JSON format object (show an example later). The fourth and subsequent arguments are the arguments to pass to the contract. Specify the order of parameters in the method signature.

Here is an example of specifying the return type in ABI JSON format. The return type is a user-defined struct with number value and string value.

```
const code = `
  function func() {
    return staticcallContract(
      '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
      'getPrice()',
      {
        type: "tuple",
        components: [
          {
            "name": "value",
            "type": "uint256"
          },
          {
            "name": "unit",
            "type": "string"
          }
        ]
      }
    );
  }`

const result = await snippetJs.interpretToString(code)
console.log(result)
```

The result will be displayed as below. The user-defined struct is mapped to a object and the "name" properties are the keys of the object.

```
{value:123,unit:"ETH"}
```
