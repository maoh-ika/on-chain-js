// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import "../interfaces/lexer/IJSLexer.sol";

contract Demo {
  struct Params {
    uint num;
    string str;
  }
  struct Params2 {
    string str;
    bool bl;
    Params params; 
    string str2;
  }
  
  struct Params4 {
    uint num;
    bool bl;
  }

  struct DynamicParams {
    string str;
    Params[] params;
  }
  
  struct StaticParams {
    uint num;
    Params4[] params;
  }

  function owner() external pure returns (address) {
    return address(uint160(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
  }
  function echo(address addr) external view returns (address) {
    console.log('echo(address addr)');
    console.log('a %s', addr);
    return addr;
  }

  function echo(uint8 a) external view returns (uint) {
    console.log('echo(uint8 a)');
    console.log('a %d', a);
    return a;
  }
  function echo(uint a) external view returns (uint) {
    console.log('echo(uint a)');
    console.log('a %d', a);
    return a;
  }
  function echo(uint[] calldata a) external view returns (uint) {
    console.log('uint[] calldata a');
    if (a.length == 0) {
      console.log('a is empty');
      return 0;
    } else {
      console.log('a %d', a[0]);
      return a[0];
    }
  }
  function echo(uint[][] calldata a) external view returns (uint) {
    console.log('uint[][] calldata a');
    if (a.length == 0) {
      console.log('a is empty');
      return 0;
    } else {
      console.log('a %d', a[0][0]);
      return a[1][0];
    }
  }
  function echo(uint[][][] calldata a) external view returns (uint) {
    console.log('uint[][][] calldata a');
    console.log('dim1 %d', a.length);
    console.log('dim2 %d', a[0].length);
    console.log('dim3 %d', a[0][0].length);
    if (a.length == 0) {
      console.log('a is empty');
      return 0;
    } else {
      console.log('a %d', a[0][0][0]);
      return a[0][0][0];
    }
  }
  function echo(bool a) external view returns (bool) {
    console.log('echo(bool a)');
    console.log('a %s', a);
    return a;
  }
  function echo(bool[] memory a) external view returns (bool) {
    console.log('bool[] memory a');
    if (a.length == 0) {
      console.log('a is empty');
      return false;
    } else {
      console.log('a %d', a[0]);
      return a[0];
    }
  }
  function echo(bool[][] calldata a) external view returns (bool) {
    console.log('bool[][] calldata a');
    if (a.length == 0) {
      console.log('a is empty');
      return false;
    } else {
      console.log('a %d', a[0][0]);
      return a[1][0];
    }
  }
  function echo(string calldata a) external view returns (string memory) {
    console.log('echo(string a)');
    console.log('a %s', a);
    return a;
  }
  function echo(string[] calldata a) external view returns (string memory) {
    console.log('echo(string[] calldata a)');
    if (a.length == 0) {
      console.log('a is empty');
      return '';
    } else {
      console.log('a %s', a[0]);
      return a[0];
    }
  }
  function echo(string[][] calldata a) external view returns (string memory) {
    console.log('echo(string[][] calldata a)');
    if (a.length == 0) {
      console.log('a is empty');
      return '';
    } else {
      console.log('a %s', a[1][0]);
      return a[1][0];
    }
  }
  function echo(Params memory a) external view returns (uint) {
    console.log('echo(Params a)');
    console.log('num %d', a.num);
    console.log('str %s', a.str);
    return a.num;
  }
  function echo(Params[] memory a) external view returns (uint) {
    console.log('echo(Params[] a)');
    if (a.length == 0) {
      console.log('a is empty');
      return 0;
    } else {
      console.log('num %d', a[0].num);
      console.log('str %s', a[0].str);
      return a[0].num;
    }
  }
  function echo(Params2 memory a) external view returns (string memory) {
    console.log('echo(Params2 a)');
    console.log('a.str %s', a.str);
    console.log('a.bl %s', a.bl);
    console.log('a.params.num %d', a.params.num);
    console.log('a.params.str %s', a.params.str);
    console.log('a.str2 %s', a.str2);
    return a.str;
  }
  function echo(Params memory a, uint b, Params memory c, string memory d, bool e) external view returns (uint) {
    console.log('echo(Params memory a, uint b, Params memory c, string memory d, bool e)');
    console.log('a.num %d', a.num);
    console.log('a.str %s', a.str);
    console.log('b %d', b);
    console.log('c.num %d', c.num);
    console.log('c.str %s', c.str);
    console.log('d %s', d);
    console.log('e %s', e);
    return a.num;
  }
  function echo(uint[] calldata a, bool[] memory d) external view returns (uint) {
    console.log('uint[] calldata a, bool[] memory d');
    if (a.length == 0) {
      console.log('a is empty');
    } else {
      console.log('a %d', a[0]);
    }
    if (d.length == 0) {
      console.log('d is empty');
    } else {
      console.log('d %d', d[0]);
    }
    return a[0];
  }
  function echo(uint[] calldata a, Params[] memory b, string[] calldata c, bool[] memory d) external view returns (uint) {
    console.log('uint[] calldata a, Params[] memory b, string[] calldata c, bool[] memory d');
    if (a.length == 0) {
      console.log('a is empty');
    } else {
      console.log('a %d', a[0]);
    }
    if (b.length == 0) {
      console.log('b is empty');
    } else {
      console.log('num %d', b[0].num);
      console.log('str %s', b[0].str);
    }
    if (c.length == 0) {
      console.log('c is empty');
    } else {
      console.log('c %s', c[0]);
    }
    if (d.length == 0) {
      console.log('d is empty');
    } else {
      console.log('d %d', d[0]);
    }
    return a[0];
  }
  function add(uint a, uint b) external view returns (uint) {
    console.log('add(uint a, uint b)');
    console.log('a %d', a);
    console.log('b %d', b);
    return a + b;
  }
  function add(bool a, bool b) external view returns (bool) {
    console.log('add(bool a, bool b)');
    console.log('a %s', a);
    console.log('b %s', b);
    return a && b;
  }
  function add(string calldata a, string calldata b) external view returns (string memory) {
    console.log('add(string a, string b)');
    console.log('a %s', a);
    console.log('b %s', b);
    return string.concat(a, b);
  }
  function returnMulti() external pure returns (uint, string memory) {
    return (1, 'a');
  }
  function returnTokenAttrs() external pure returns (IJSLexer.TokenAttrs memory ret) {
    ret.value = abi.encode(88);
    ret.tokenCode = 77;
    ret.size = 99;
    ret.allowFollowingRegex = true;
    ret.tokenType = IJSLexer.TokenType.number;
  }
  function returnToken() external pure returns (IJSLexer.Token memory ret) {
    ret.startPos = 11;
    ret.endPos = 22;
    ret.line = 33;
    ret.attrs.value = abi.encode('comment');
    ret.attrs.tokenCode = 77;
    ret.attrs.size = 99;
    ret.attrs.allowFollowingRegex = true;
    ret.attrs.tokenType = IJSLexer.TokenType.comment;
  }
  function returnTokens() external pure returns (IJSLexer.Token[] memory ret) {
    ret = new IJSLexer.Token[](10);
    for (uint i = 0; i < 10; ++i) {
      IJSLexer.Token memory token;
      token.startPos = 11;
      token.endPos = 22;
      token.line = 33;
      token.attrs.value = abi.encode(88);
      token.attrs.tokenCode = 77;
      token.attrs.size = 99;
      token.attrs.allowFollowingRegex = true;
      token.attrs.tokenType = IJSLexer.TokenType.number;
      ret[i] = token;
    }
  }
  function returnDynamicParams() external pure returns (DynamicParams memory) {
    DynamicParams memory dyParams;
    dyParams.str = 'str';
    Params[] memory params = new Params[](2);
    params[0].num = 99;
    params[0].str = 'st';
    params[1].num = 88;
    params[1].str = 'st2';
    dyParams.params = params;
    return dyParams;
  }
  function returnStaticParams() external pure returns (StaticParams memory) {
    StaticParams memory stParams;
    stParams.num = 77;
    Params4[] memory params = new Params4[](2);
    params[0].num = 99;
    params[0].bl = true;
    params[1].num = 88;
    params[1].bl = false;
    stParams.params = params;
    return stParams;
  }
  function returnUintArray(uint[] calldata a) external view returns (uint[] memory) {
    console.log('uint[] calldata a');
    console.log('len %d', a.length);
    return a;
  }
  function returnBoolArray(bool[] memory a) external view returns (bool[] memory) {
    console.log('bool[] memory a');
    console.log('len %d', a.length);
    return a;
  }
  function returnArrayAndStatic(uint[] memory numArray, uint num, bool[] memory blArray, bool bl) external view returns (uint[] memory, uint, bool[] memory, bool) {
    console.log('uint[] memory numArray, uint num, bool[] memory blArray, bool bl');
    console.log('numArray len %d', numArray.length);
    console.log('num %d', num);
    console.log('blArray len %d', blArray.length);
    console.log('bl %d', bl);
    return(numArray, num, blArray, bl);
  }
  function echoMultiArry(uint[] memory numArray, bool[] memory blArray) external view returns (uint[] memory, bool[] memory) {
    console.log('uint[] memory numArray, bool[] memory blArra');
    console.log('numArray len %d', numArray.length);
    console.log('blArray len %d', blArray.length);
    return(numArray, blArray);
  }
}