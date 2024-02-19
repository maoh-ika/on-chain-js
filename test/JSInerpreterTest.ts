import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'
import { makeRunContext } from '../scripts/runContext'

describe('JSInterpreterTest', function () {
  const gasLimit = 100000000
  const proxyAddress = addresses['localhost']['SnippetJS']['SnippetJSProxy']
  const measuerAddress = addresses['localhost']['utils']['MeasureGas']

  async function deployFixture() {
    const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545/')
    return new ethers.Contract(
      measuerAddress,
      measureAbi.abi,
      provider
    )
  }

  async function interpret(code: string, useArgs: boolean=false, initState: any=undefined) {
    const state = initState === undefined ? makeRunContext(useArgs) : initState
    const measure = await loadFixture(deployFixture);
    //const res = await measure.measureProxy2(proxyAddress, code, { gasLimit: gasLimit })
    const res = await measure.measureSnippet(proxyAddress, code, state, { gasLimit: gasLimit })
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
  
  it('arg defult', async function () {
    const code = `function func(arg=1) { return arg; }`
    const { result, gas } = await interpret(code)
    console.log(`arg_default: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1');
  })
  it('arg', async function () {
    const code = `function func(arg) { return arg; }`
    const { result, gas } = await interpret(code, true)
    console.log(`arg: ${gas}`)
    expect(result).to.equal('argValue');
  })
  it('while_continue', async function () {
    const code = `function func() { var a = 1; while (a < 3) { ++a; continue; ++a; }; return a; }`
    const { result, gas } = await interpret(code)
    console.log(`while: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('while_break', async function () {
    const code = `function func() { var a = 1; while (a < 3) { break; ++a; }; return a; }`
    const { result, gas } = await interpret(code)
    console.log(`while: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1');
  })
  it('while', async function () {
    const code = `function func() { var a = 1; while (a < 3) { ++a; }; return a; }`
    const { result, gas } = await interpret(code)
    console.log(`while: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('logical or2', async function () {
    const code = `function func() { return 0 || false; }`
    const { result, gas } = await interpret(code)
    console.log(`logical: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('false');
  })
  it('logical or', async function () {
    const code = `function func() { return 2 || false; }`
    const { result, gas } = await interpret(code)
    console.log(`logical: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('logical and3', async function () {
    const code = `function func() { return 2 && (1 + 2); }`
    const { result, gas } = await interpret(code)
    console.log(`logical: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('logical and2', async function () {
    const code = `function func() { return ''; }`
    //const code = `function func() { return '' && 2; }`
    const { result, gas } = await interpret(code)
    console.log(`logical: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('');
  })
  it('logical and', async function () {
    const code = `function func() { return 1 && 2; }`
    const { result, gas } = await interpret(code)
    console.log(`logical: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('tokenAttributes', async function () {
    const code = `function func() { return tokenAttributes["year"]; }`
    const { result, gas } = await interpret(code)
    console.log(`tokenAttribute: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('0.000000000000000001');
  })
  it('ethreumBlock', async function () {
    const code = `function func() { return ethreumBlock["blockNumber"]; }`
    const { result, gas } = await interpret(code)
    console.log(`ethreumBloc: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('0.000000000000000222');
  })
  it('object-incl', async function () {
    const code = `function func() { var c = {a:1, b:2}; ++c["b"]; return c["b"]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('object-assignment2', async function () {
    const code = `function func() { var c = {a:1, b:2}; c["b"] = [3,4]; return c["b"][1]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('4');
  })
  it('object-assignment', async function () {
    const code = `function func() { var c = {a:1, b:2}; c["b"] = 3; return c["b"]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('object-member-nest3', async function () {
    const code = `function func() { var c = [{a:[0, {c:1}],b:2},3]; return c[0]["b"]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('object-member-nest2', async function () {
    const code = `function func() { var c = [{a:[{c:1}]}]; return c[0]["a"][0]["c"]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1');
  })
  it('object-member-nest', async function () {
    const code = `function func() { var c = {a:[{b:[1]}]}; return c["a"][0]["b"][0]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1');
  })
  it('object-member-dot-incl', async function () {
    const code = `function func() { var c = {a:{b:2}}; ++c.a.b; return c.a.b; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('object-member-dot3', async function () {
    const code = `function func() { var c = [1, {a:2}]; return c[1].a; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('object-member-dot2', async function () {
    const code = `function func() { var c = {a:{b:2}}; return c.a.b; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('object-member-dot', async function () {
    const code = `function func() { var c = {a:1}; return c.a; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1');
  })
  it('object-member', async function () {
    const code = `function func() { var c = {a:1}; var a = "a"; return c[a]; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1');
  })
  it('object-array-nest', async function () {
    const code = `function func() { var c = {a:[{b:[1]}]}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":[{"b":[1]}]}');
  })
  it('array-object-nest', async function () {
    const code = `function func() { var c = [{a:[{c:1}]}]; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`arra: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[{"a":[{"c":1}]}]');
  })
  it('object_nest-array', async function () {
    const code = `function func() { var c = {a:[[1,2]]}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`object_nes: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":[[1,2]]}');
  })
  it('object_in-array-object2', async function () {
    const code = `function func() { var c = {a: [{b:3, d:[1]}, 2]}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`object_i: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":[{"b":3,"d":[1]},2]}');
  })
  it('object_in-array-object', async function () {
    const code = `function func() { var c = {a: [{b:3}, 2]}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`object_i: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":[{"b":3},2]}');
  })
  it('object_array', async function () {
    const code = `function func() { var c = {a: [1, 2]}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`object_arra: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":[1,2]}');
  })
  it('object_nest', async function () {
    const code = `function func() { var c = {a: {b: 1}, c: 4}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`object_nes: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":{"b":1},"c":4}');
  })
  it('object', async function () {
    const code = `function func() { var c = {a: 1}; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`objec: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('{"a":1}');
  })
  it('array property length3', async function () {
    const code = `function func(arr=[1,2]) { return arr.length; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('array property length2', async function () {
    const code = `function func() { var c = [0, [2,3,4]]; return c[1].length; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('array property length', async function () {
    const code = `function func() { var c = [0, [2,3]]; return c.length; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('array assign4', async function () {
    const code = `function func() { var c = [0, [2,3]]; ++c[1][1] return c[1][1]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('4');
  })
  it('array assign3', async function () {
    const code = `function func() { var c = [1]; ++++c[0]; return c[0]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('array assign2', async function () {
    const code = `function func() { var c = [1]; c[0] = [2,3] return c[0]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[2,3]');
  })
  it('array assign', async function () {
    const code = `function func() { var c = [1]; c[0] = 2; return c[0]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('array assign', async function () {
    const code = `function func() { var c = [1]; c[0] = 2 return c[0]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('array index4', async function () {
    const code = `function func() { var c = [1, [2,3], 5]; return c[1][1]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('array index3', async function () {
    const code = `function func() { var c = [1, [2,3], 5]; return c[1]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[2,3]');
  })
  it('array index2', async function () {
    const code = `function func() { var c = [1, 4, 5]; return c[1] + c[2]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(9);
  })
  it('array index', async function () {
    const code = `function func() { var c = [1, 2]; return c[0]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('array decl', async function () {
    const code = `function func() { var c = [1, 2]; return --c; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('array incl', async function () {
    const code = `function func() { var c = [1]; return ++c; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('array rem', async function () {
    const code = `function func() { var c = [1, 2]; var d = [3, 4]; return c % d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('array div', async function () {
    const code = `function func() { var c = [1, 2]; var d = [3, 4]; return c / d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('array mul', async function () {
    const code = `function func() { var c = [1, 2]; var d = [3, 4]; return c * d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('array sub', async function () {
    const code = `function func() { var c = [1, 2]; var d = [3, 4]; return c - d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('array add4', async function () {
    const code = `function func() { var c = [1, 2]; var d = null; return c + d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1,2null');
  })
  it('array add3', async function () {
    const code = `function func() { var c = [1, 2]; var d = "a"; return c + d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1,2a');
  })
  it('array add2', async function () {
    const code = `function func() { var c = [1, 2]; var d = 1; return c + d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1,21');
  })
  it('array add', async function () {
    const code = `function func() { var c = [1, 2]; var d = [3, 4]; return c + d; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('1,23,4');
  })
  it('array multi dims', async function () {
    const code = `function func() { var c = [
      [1, 2],
      [3, 4],
      [5, 6]
    ]; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`,: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[[1,2],[3,4],[5,6]]');
  })
  it('array3', async function () {
    const code = `function func() { var c = [1, null, "3", "a", [4, 5], []]; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[1,null,"3","a",[4,5],[]]');
  })
  it('array in arrays', async function () {
    const code = `function func() { return [[1, 2], 3]; }`
    const { result, gas } = await interpret(code)
    console.log(`array: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[[1,2],3]');
  })
  it('array', async function () {
    const code = `function func() { return [1, 2, 3]; }`
    const { result, gas } = await interpret(code)
    console.log(`arra: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('[1,2,3]');
  })
  it('void', async function () {
    const code = `function func() { return void "aa"; }`
    const { result, gas } = await interpret(code)
    console.log(`voi: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('undefined');
  })
  it('typeof2', async function () {
    const code = `function func() { return typeof "" + typeof 1 + typeof null + typeof true + typeof undefined; }`
    const { result, gas } = await interpret(code)
    console.log(`typeof: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('stringnumberobjectbooleanundefined');
  })
  it('typeof', async function () {
    const code = `function func() { var c = 1; return typeof c; }`
    const { result, gas } = await interpret(code)
    console.log(`typeo: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('number');
  })
  it('bitwiseNot3', async function () {
    const code = `function func() { var c = null; return ~c; }`
    const { result, gas } = await interpret(code)
    console.log(`bitwiseNot: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('bitwiseNot2', async function () {
    const code = `function func() { var c = -2345; return ~c; }`
    const { result, gas } = await interpret(code)
    console.log(`bitwiseNot: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(2344);
  })
  it('bitwiseNot', async function () {
    const code = `function func() { var c = 13; return ~c; }`
    const { result, gas } = await interpret(code)
    console.log(`bitwiseNo: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-14);
  })
  it('logicalNot3', async function () {
    const code = `function func() { return !!true }`
    const { result, gas } = await interpret(code)
    console.log(`logicalNot: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('true');
  })
  it('logicalNot2', async function () {
    const code = `function func() { return !0 }`
    const { result, gas } = await interpret(code)
    console.log(`logicalNot: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('true');
  })
  it('logicalNot', async function () {
    const code = `function func() { return !1 }`
    const { result, gas } = await interpret(code)
    console.log(`logicalNo: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('false');
  })
  it('unary_plus6', async function () {
    const code = `function func() { return +'hello'; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_plus: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('NaN');
  })
  it('unary_plus5', async function () {
    const code = `function func() { return +false; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_plus: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(0);
  })
  it('unary_plus4', async function () {
    const code = `function func() { return +true; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_plus: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('unary_plus3', async function () {
    const code = `function func() { return +'  '; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_plus: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(0);
  })
  it('unary_plus2', async function () {
    const code = `function func() { return +-3; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_plus: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-3);
  })
  it('unary_plus', async function () {
    const code = `function func() { return +3; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_plu: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('unary_minus_order', async function () {
    const code = `function func() { return -(3 + 2); }`
    const { result, gas } = await interpret(code)
    console.log(`unary_minus_orde: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-5);
  })
  it('unary_minus_multi', async function () {
    const code = `function func() { var c = 3; return 1 + - - c; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_minus_mult: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(4);
  })
  it('unary_minus', async function () {
    const code = `function func() { var c = 3; return 1 + -c; }`
    const { result, gas } = await interpret(code)
    console.log(`unary_minu: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-2);
  })
  it('assign_xor', async function () {
    const code = `function func() { var c = 15; c ^= 44; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_xo: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(35);
  })
  it('assign_or', async function () {
    const code = `function func() { var c = 15; c |= 44; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_o: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(47);
  })
  it('assign_rightshift', async function () {
    const code = `function func() { var c = 11; c >>= 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_rightshif: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('assign_leftshift', async function () {
    const code = `function func() { var c = 11; c <<= 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_leftshif: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(88);
  })
  it('assign_remain', async function () {
    const code = `function func() { var c = 11; c %= 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_remai: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(2);
  })
  it('assign_div2', async function () {
    const code = `function func() { var c = .3; c /= 5; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_div: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(0.06);
  })
  it('assign_div', async function () {
    const code = `function func() { var c = 2; c /= 5; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_di: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(0.4);
  })
  it('assign_exp_null', async function () {
    const code = `function func() { var c = 2; c **= null; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_exp_nul: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('assign_exp_minus', async function () {
    const code = `function func() { var c = -2; c **= 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_exp_minu: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-8);
  })
  it('assign_exp', async function () {
    const code = `function func() { var c = 2; c **= 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_ex: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(8);
  })
  it('assign_sub', async function () {
    const code = `function func() { var c = 1; c -= 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_su: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-2);
  })
  it('assign_add_str', async function () {
    const code = `function func() { var c = 'a' + 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_add_st: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('a3');
  })
  it('assign_add', async function () {
    const code = `function func() { var c = 1; c += 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assign_ad: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(4);
  })
  it('assignment', async function () {
    const code = `function func() { var c = 0; c = 3; return c; }`
    const { result, gas } = await interpret(code)
    console.log(`assignmen: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('for_if', async function () {
    const code = 'function func() { var c = 0; for (var i = 0; i < 3; ++i) { c++; } if (c === 3) { return -3; } else { return 1; } }'
    const { result, gas } = await interpret(code)
    console.log(`for_i: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-3);
  })
  it('for_continue', async function () {
    const code = 'function func() { var c = 0; for (var i = 0; i < 3; ++i) { c++; continue; c++; } return c; }'
    const { result, gas } = await interpret(code)
    console.log(`for_break: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('for_break', async function () {
    const code = 'function func() { var c = 0; for (var i = 0; i < 3; ++i) { c++; break; } return c; }'
    const { result, gas } = await interpret(code)
    console.log(`for_break: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('for', async function () {
    const code = 'function func() { var c = 0; for (var i = 0; i < 3; ++i) { c++; } return c; }'
    const { result, gas } = await interpret(code)
    console.log(`fo: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('incl_order2', async function () {
    const code = 'function func() { var c = 1; return c++ + ++c + 1; }'
    const { result, gas } = await interpret(code)
    console.log(`incl_order: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(5);
  })
  it('incl_order', async function () {
    const code = 'function func() { var c = 1; return ++c + ++c; }'
    const { result, gas } = await interpret(code)
    console.log(`incl_orde: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(5);
  })
  it('decrement_multi', async function () {
    const code = 'function func() { var c = 1; ----c; return c; }'
    const { result, gas } = await interpret(code)
    console.log(`decrement_mult: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('increment_multi', async function () {
    const code = 'function func() { var c = -1; ++++c; return c; }'
    const { result, gas } = await interpret(code)
    console.log(`increment_mult: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('declement_post', async function () {
    const code = 'function func() { var c = 0; c--; return c; }'
    const { result, gas } = await interpret(code)
    console.log(`declement_pos: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('decrement_pre', async function () {
    const code = 'function func() { var c = 0; --c; return c; }'
    const { result, gas } = await interpret(code)
    console.log(`decrement_pr: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('inclement_post', async function () {
    const code = 'function func() { var c = 0; c++; return c; }'
    const { result, gas } = await interpret(code)
    console.log(`inclement_pos: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('increment_pre', async function () {
    const code = 'function func() { var c = 0; ++c; return c; }'
    const { result, gas } = await interpret(code)
    console.log(`increment_pr: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('if_elseif2', async function () {
    const code = 'function func() { var c = 0; var d = false; if (c) { return 1; } else if (d)  { return 2 + 3 + 4; } else { return c } }'
    const { result, gas } = await interpret(code)
    console.log(`if_elseif: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(0);
  })
  it('if_elseif', async function () {
    const code = 'function func() { var c = false; var d = 1; if (c) { return 1; } else if (d)  { return 2 + 3 + 4; } else { return c } }'
    const { result, gas } = await interpret(code)
    console.log(`if_elsei: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(9);
  })
  it('if_else', async function () {
    const code = 'function func() { var c = false; if (c) { return 1; } else { return 2 + 3 + 4; } }'
    const { result, gas } = await interpret(code)
    console.log(`if_els: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(9);
  })
  it('if_post_incl', async function () {
    const code = 'function func() { var c = 0; if (c++) { return 1; } else { return 2; } }'
    const { result, gas } = await interpret(code)
    console.log(`if_post_inc: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(2);
  })
  it('if', async function () {
    const code = 'function func() { var c = true; if (c) { return 1; } else { return 2; } }'
    const { result, gas } = await interpret(code)
    console.log(`i: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('biop_bitwiseXor3', async function () {
    const code = makeBiopCode(-12, '^', '-345')
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseXor: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(339);
  })
  it('biop_bitwiseXor2', async function () {
    const code = makeBiopCode(-12, '^', -345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseXor: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(339);
  })
  it('biop_bitwiseXor1', async function () {
    const code = makeBiopCode(12, '^', -345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseXor: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-341);
  })
  it('biop_bitwiseXor', async function () {
    const code = makeBiopCode(12, '^', 345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseXo: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(341);
  })
  it('biop_bitwiseAnd4', async function () {
    const code = makeBiopCode('"a"', '&', -345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseAnd: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(0);
  })
  it('biop_bitwiseAnd3', async function () {
    const code = makeBiopCode(-12, '&', -345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseAnd: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-348);
  })
  it('biop_bitwiseAnd2', async function () {
    const code = makeBiopCode(12, '&', -345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseAnd: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(4);
  })
  it('biop_bitwiseAnd', async function () {
    const code = makeBiopCode(12, '&', 345)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseAn: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(8);
  })
  it('biop_bitwiseOr3', async function () {
    const code = makeBiopCode(-1, '|', '"f"')
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseOr: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('biop_bitwiseOr2', async function () {
    const code = makeBiopCode(-1, '|', -2)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseOr: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('biop_bitwiseOr', async function () {
    const code = makeBiopCode(1, '|', 2)
    const { result, gas } = await interpret(code)
    console.log(`biop_bitwiseO: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('biop_unsignedRightShift', async function () {
    const code = makeBiopCode(-1, '>>>', 1)
    const { result, gas } = await interpret(code)
    console.log(`biop_unsignedRightShif: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(9223372036854776000);
  })
  it('op_order', async function () {
    const code = `function func() { return (1 + 2) * 3 / (4 + 5); }`
    const { result, gas } = await interpret(code)
    console.log(`op_orde: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('add_mul_order2', async function () {
    const code = `function func() { return 1 + 2 * 3 * 4 + 5; }`
    const { result, gas } = await interpret(code)
    console.log(`add_mul_order: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(30);
  })
  it('add_mul_order', async function () {
    const code = `function func() { return (1 + 2) * 3; }`
    const { result, gas } = await interpret(code)
    console.log(`add_mul_orde: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(9);
  })
  it('add_number_str', async function () {
    const code = makeBiopCode("'a'", '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_st: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('a2');
  })
  it('add_number_str2', async function () {
    const code = makeBiopCode(0.2, '+', "'a'")
    const { result, gas } = await interpret(code)
    console.log(`add_number_str: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('0.2a');
  })
  it('add_number_number', async function () {
    const code = makeBiopCode(0, '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_numbe: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(2);
  })
  it('add_number_number2', async function () {
    const code = makeBiopCode(1, '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('add_number_number3', async function () {
    const code = makeBiopCode(8, '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(10);
  })
  it('add_number_number4', async function () {
    const code = makeBiopCode(-1, '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(1);
  })
  it('add_number_number5', async function () {
    const code = makeBiopCode(1, '+', -2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('add_number_number6', async function () {
    const code = makeBiopCode(1.0, '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('add_number_number7', async function () {
    const code = makeBiopCode('.1', '+', 2)
    const { result, gas } = await interpret(code)
    console.log(`add_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(2.1);
  })
  
  // sub
  it('sub_number_number', async function () {
    const code = makeBiopCode(0, '-', 2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_numbe: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-2);
  })
  it('sub_number_number2', async function () {
    const code = makeBiopCode(1, '-', 2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('sub_number_number3', async function () {
    const code = makeBiopCode(8, '-', 2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(6);
  })
  it('sub_number_number4', async function () {
    const code = makeBiopCode(-1, '-', 2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-3);
  })
  it('sub_number_number5', async function () {
    const code = makeBiopCode(1, '-', -2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(3);
  })
  it('sub_number_number6', async function () {
    const code = makeBiopCode(1.0, '-', 2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1);
  })
  it('sub_number_number7', async function () {
    const code = makeBiopCode('.1', '-', 2)
    const { result, gas } = await interpret(code)
    console.log(`sub_number_number: ${gas}`)
    gasTotal += gas;
    expect(+result).to.equal(-1.9);
  })
  it('radix', async function () {
    const code = `function func() { var s = 0x3; return s; }`
    const { result, gas } = await interpret(code)
    console.log(`radix: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('str_radix', async function () {
    const code = `function func() { var s = '0x3'; return +s; }`
    const { result, gas } = await interpret(code)
    console.log(`str_radix: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('str_radix2', async function () {
    const code = `function func() { var s = '0o17'; return +s; }`
    const { result, gas } = await interpret(code)
    console.log(`str_radix2: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('15');
  })
  it('str_radix3', async function () {
    const code = `function func() { var s = '0b11'; return +s; }`
    const { result, gas } = await interpret(code)
    console.log(`str_radix2: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('3');
  })
  it('str_octal', async function () {
    const code = `function func() { var s = '017'; return +s; }`
    const { result, gas } = await interpret(code)
    console.log(`str_octal: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('15');
  })
  it('comment_block', async function () {
    const code = `function func(/*comment*/) { /*comment*/
      /* test comment // comment */
      /* comment
      * comment
      * comment
      */
      return 2; // comment
    }`
    const { result, gas } = await interpret(code)
    console.log(`comment_block: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
  it('comment_line', async function () {
    const code = `function func() { //comment
      // test comment // comment
      // comment
      return 2; // comment
    }`
    const { result, gas } = await interpret(code)
    console.log(`comment_line: ${gas}`)
    gasTotal += gas;
    expect(result).to.equal('2');
  })
});