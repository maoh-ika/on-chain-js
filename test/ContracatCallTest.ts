import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { makeRunContext } from '../scripts/runContext'
import { addresses } from '../scripts/addresses'

describe('ContracatCallTest', function () {
  const gasLimit = 1000000000

  async function deployFixture() {
    const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545/')
    return new ethers.Contract(
      addresses.localhost.utils.MeasureGas,
      measureAbi.abi,
      provider
    )
  }

  async function interpret(code: string, useArgs: boolean=false) {
    const state = makeRunContext(useArgs)
    const measure = await loadFixture(deployFixture);
    const res = await measure.measureSnippet(addresses.localhost.SnippetJS.SnippetJSProxy, code, state, { gasLimit: gasLimit })
    return { result: res[0], gas: +res[1] }
  } 
  
  function makeBiopCode(left: any, op: string, right: any): string {
    return `function func() { return ${left} ${op} ${right};}`
  }

  let gasTotal = 0

  before(async function() {
    await loadFixture(deployFixture);
  });

  after(async function() {
    console.log(`GAS TOTAL: ${gasTotal}`)
  })
  
  it('temp', async function () {
    const code = `
    function tokenize(code="function run() { return 'SnippetJS'; }") {
      return staticcallContract(
        '${addresses.localhost.SnippetJS.SnippetJSProxy}',
        'tokenize(string,(bool))',
        {
          "components": [
            {
              "components": [
                {
                  "name": "value",
                  "type": "bytes"
                },
                {
                  "name": "tokenCode",
                  "type": "uint256"
                },
                {
                  "name": "size",
                  "type": "uint256"
                },
                {
                  "name": "allowFollowingRegex",
                  "type": "bool"
                },
                {
                  "name": "tokenType",
                  "type": "uint256"
                }
              ],
              "name": "attrs",
              "type": "tuple"
            },
            {
              "name": "startPos",
              "type": "uint256"
            },
            {
              "name": "endPos",
              "type": "uint256"
            },
            {
              "name": "line",
              "type": "uint256"
            }
          ],
          "type": "tuple[]"
        },
        code,
        { ignoreComment: false }).length;
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_return_tokens: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('9');
  })
  it('call_contract_return_tokens', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnTokens()',
        {
          "type": "tuple[]",
          "components": [
            {
              "components": [
                {
                  "name": "value",
                  "type": "bytes"
                },
                {
                  "name": "tokenCode",
                  "type": "uint256"
                },
                {
                  "name": "size",
                  "type": "uint256"
                },
                {
                  "name": "allowFollowingRegex",
                  "type": "bool"
                },
                {
                  "name": "tokenType",
                  "type": "uint256"
                }
              ],
              "name": "attrs",
              "type": "tuple"
            },
            {
              "name": "startPos",
              "type": "uint256"
            },
            {
              "name": "endPos",
              "type": "uint256"
            },
            {
              "name": "line",
              "type": "uint256"
            }
          ]
        }
      ).length;
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_return_tokens: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('10');
  })
  it('call_contract_return_token', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnToken()',
        {
          "type": "tuple",
          "components": [
            {
              "components": [
                {
                  "name": "value",
                  "type": "bytes"
                },
                {
                  "name": "tokenCode",
                  "type": "uint256"
                },
                {
                  "name": "size",
                  "type": "uint256"
                },
                {
                  "name": "allowFollowingRegex",
                  "type": "bool"
                },
                {
                  "name": "tokenType",
                  "type": "uint256"
                }
              ],
              "name": "attrs",
              "type": "tuple"
            },
            {
              "name": "startPos",
              "type": "uint256"
            },
            {
              "name": "endPos",
              "type": "uint256"
            },
            {
              "name": "line",
              "type": "uint256"
            }
          ]
        }
      ).startPos;
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_return_token: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('11');
  })
  it('call_contract_return_tokenattrs', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnTokenAttrs()',
        {
          type: "tuple",
          components: [
            {
              "name": "value",
              "type": "bytes"
            },
            {
              "name": "tokenCode",
              "type": "uint256"
            },
            {
              "name": "size",
              "type": "uint256"
            },
            {
              "name": "allowFollowingRegex",
              "type": "bool"
            },
            {
              "name": "tokenType",
              "type": "uint256"
            }
          ]
        }
      ).tokenCode;
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_return_tokenattrs: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('77');
  })
  it('call_contract_array_multi2', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint256[],(uint256,string)[],string[],bool[])',
        {type: "uint256"},
        [44,55],
        [{num:77,str:'a'},{num:88,str:'b'}],
        ['c','d'],
        [true,false]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_multi2: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('44');
  })
  it('call_contract_array_multi', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint256[],bool[])',
        {type: "uint256"},
        [44,55],
        [true,false]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_multi: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('44');
  })
  it('call_contract_array_struct', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo((uint256,string)[])',
        {type: "uint256"},
        [{num:77,str:'a'},{num:88,str:'b'}]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_struct: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('77');
  })
  it('call_contract_array_string2', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(string[][])',
        {type: "string"},
        [['aa', 'bb'], ['cc', 'dd', 'ee']]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_string2: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('cc');
  })
  it('call_contract_array_string', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(string[])',
        {type: "string"},
        ['aa', 'bb']
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_string: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('aa');
  })
  it('call_contract_array_bool2', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(bool[][])',
        {type: "bool"},
        [[false, true], [true, true]]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_bool2: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('true');
  })
  it('call_contract_array_bool', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(bool[])',
        {type: "bool"},
        [false, true]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_bool: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('false');
  })
  it('call_contract_array_number_3', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint256[][][])',
        {type: "uint256"},
        [[[88]], [[99]]]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_number_3: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('88');
  })
  it('call_contract_array_number_2', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint256[][])',
        {type: "uint256"},
        [[77], [88]]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_number_2: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('88');
  })
  it('call_contract_array_number', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint256[])',
        {type: "uint256"},
        [77,88,99]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_array_number: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('77');
  })
  it('call_contract_multi', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnMulti()',
        [
          {
            type: "uint256",
            name: "num"
          },
          {
            type: "string",
            name: "str"
          }
        ]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_multi: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[1,"a"]');
  })
  it('call_contract_multi', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo((uint256,string),uint256,(uint256,string),string,bool)',
        {type: "uint256"},
        {num:99,str:"a"},
        88,
        {num:77,str:"b"},
        "c",
        true
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_multi: ${gas}`)
    gasTotal += gas;
    expect(result as string).to.equal('99');
  })
  it('call_contract_nest', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo((string,bool,(uint256,string),string))',
        {type: "string"},
        {str:"a",bl:true,params:{num:77,str:"b"},str2:"c"}
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_multi: ${gas}`)
    gasTotal += gas;
    expect(result as string).to.equal('a');
  })
  it('call_contract_stuct1', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo((uint256,string))',
        {type: "uint256"},
        {num:99,str:"a"}
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract: ${gas}`)
    gasTotal += gas;
    expect(result as string).to.equal('99');
  })
  it('call_contract_str', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'add(string,string)',
        {type: "string"},
        'abc',
        'bd'
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract: ${gas}`)
    gasTotal += gas;
    expect(result as string).to.equal('abcbd');
  })
  it('call_contract_str1', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(string)',
        {type: "string"},
        'abc'
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract: ${gas}`)
    gasTotal += gas;
    expect(result as string).to.equal('abc');
  })
  it('call_contract_uint[]_uint_bool[]_bool', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnArrayAndStatic(uint256[],uint256,bool[],bool)',
        [{type: "uint256[]"},{type: "uint256"},{type: "bool[]"},{type: "bool"}],
        [0,1,2],
        3,
        [true, false, true],
        false
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint[]_uint_bool[]_bool: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[[0,1,2],3,[true,false,true],false]');
  })
  it('call_contract_uint[]bool[]', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echoMultiArry(uint256[],bool[])',
        [{type: "uint256[]"},{type: "bool[]"}],
        [0,1,2],
        [true, false, true]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint[]bool[]: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[[0,1,2],[true,false,true]]');
  })
  it('call_contract_bool', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'add(bool,bool)',
        {type: "bool"},
        true,
        true
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_bool: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('true');
  })
  it('call_contract_bool1', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(bool)',
        {type: "bool"},
        true
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_bool: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('true');
  })
  it('call_contract_ret_bool[]', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnBoolArray(bool[])',
        {type: "bool[]"},
        [true, false, true]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_bool[]: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[true,false,true]');
  })
  it('call_contract_uint', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'add(uint256,uint256)',
        {type: "uint256"},
        1,
        2
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('call_contract_uint8', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint8)',
        {type: "uint256"},
        2
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint1: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('call_contract_uint1', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(uint256)',
        {type: "uint256"},
        2
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint1: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('call_contract_ret_uint[]', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnUintArray(uint256[])',
        {type: "uint256[]"},
        [0,1,2]
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint[]: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[0,1,2]');
  })
  it('call_contract_address', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'echo(address)',
        {type: "address"},
        0x9175bbea09F865CF034f6430bA4B80c9dDcCc853
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint1: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('0x9175bbea09F865CF034f6430bA4B80c9dDcCc853'.toLowerCase());
  })
  it('call_contract_dynamicParams', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnDynamicParams()',
        {
          "components": [
            {
              "internalType": "string",
              "name": "str",
              "type": "string"
            },
            {
              "components": [
                {
                  "internalType": "uint256",
                  "name": "num",
                  "type": "uint256"
                },
                {
                  "internalType": "string",
                  "name": "str",
                  "type": "string"
                }
              ],
              "internalType": "struct Demo.Params4[]",
              "name": "params",
              "type": "tuple[]"
            }
          ],
          "internalType": "struct Demo.DynamicParams",
          "name": "",
          "type": "tuple"
        }
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint1: ${gas}`)
    gasTotal += gas;
    const res = JSON.parse(result) 
    expect(res.str).to.equal('str');
    expect(res.params[0].num).to.equal(99);
    expect(res.params[0].str).to.equal('st');
    expect(res.params[1].num).to.equal(88);
    expect(res.params[1].str).to.equal('st2');
  })
  it('call_contract_staticParams', async function () {
    const code = `
    function func() {
      return staticcallContract(
        '${addresses.localhost.utils.Demo}',
        'returnStaticParams()',
        {
          "components": [
            {
              "internalType": "uint256",
              "name": "num",
              "type": "uint256"
            },
            {
              "components": [
                {
                  "internalType": "uint256",
                  "name": "num",
                  "type": "uint256"
                },
                {
                  "internalType": "bool",
                  "name": "bl",
                  "type": "bool"
                }
              ],
              "internalType": "struct Demo.Params4[]",
              "name": "params",
              "type": "tuple[]"
            }
          ],
          "internalType": "struct Demo.StaticParams",
          "name": "",
          "type": "tuple"
        }
      );
    }`
    const { result, gas } = await interpret(code)
    console.log(`call_contract_uint1: ${gas}`)
    gasTotal += gas;
    console.log(result)
    const res = JSON.parse(result) 
//    expect(res.num).to.equal(77);
//    expect(res.params[0].num).to.equal(99);
//    expect(res.params[0].bl).to.equal(true);
//    expect(res.params[1].num).to.equal(88);
//    expect(res.params[1].bl).to.equal(false);
  })
});