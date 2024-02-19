import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'
import { makeRunContext } from '../scripts/runContext'

describe('JSConstantTest', function () {
  const gasLimit = 10000000
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
    const res = await measure.measureSnippet(proxyAddress, code, state, { gasLimit: gasLimit })
    return { result: res[0], gas: +res[1] }
  }
  
  let gasTotal = 0

  function makeTest(name: string, code: string, expected: any, only: boolean=false) {
    const testFunc = only ? it.only : it
    testFunc(`${name}`, async function () {
      const { result, gas } = await interpret(code)
      console.log(`${name}: ${gas}`)
      gasTotal += gas;
      expect(result).to.equal(expected);
    })
  }
  
  function makeTestError(name: string, code: string, errMsg: string, only: boolean=false) {
    const testFunc = only ? it.only : it
    testFunc(`${name}`, async function () {
      try {
        const { result, gas } = await interpret(code)
        assert.fail()
      } catch (err) {
        assert.throws(function() { throw err }, Error, errMsg)
      }
    })
  }

  before(async function() {
    await loadFixture(deployFixture);
  });

  after(async function() {
    console.log(`GAS TOTAL: ${gasTotal}`)
  })

  describe('integer', function () {
    makeTest('number_integer_zero', `function func() { return 0; }`, '0')
    makeTest('number_integer_plus', `function func() { return 1; }`, '1')
    makeTest('number_integer_plus2', `function func() { return 2; }`, '2')
    makeTest('number_integer_plus3', `function func() { return 99; }`, '99')
    makeTest('number_integer_plus_u32max', `function func() { return 4294967295; }`, '4294967295')
    makeTest('number_integer_plus_u64max', `function func() { return 18446744073709551615; }`, '18446744073709551615')
    makeTest('number_integer_minus', `function func() { return -1; }`, '-1')
    makeTest('number_integer_minus2', `function func() { return -2; }`, '-2')
    makeTest('number_integer_minus3', `function func() { return -99; }`, '-99')
    makeTest('number_integer_minus_u32max', `function func() { return -4294967295; }`, '-4294967295')
    makeTest('number_integer_minus_u64max', `function func() { return -18446744073709551615; }`, '-18446744073709551615')
  })
  describe('decimal', function () {
    makeTest('number_decimal_zero', `function func() { return 0.0; }`, '0')
    makeTest('number_decimal_plus', `function func() { return 1.1; }`, '1.1')
    makeTest('number_decimal_plus2', `function func() { return 2.123; }`, '2.123')
    makeTest('number_decimal_plus3', `function func() { return 99.999; }`, '99.999')
    makeTest('number_decimal_plus4', `function func() { return 0.123; }`, '0.123')
    makeTest('number_decimal_plus4', `function func() { return 0.0900; }`, '0.09')
    makeTest('number_decimal_plus5', `function func() { return .001; }`, '0.001')
    makeTest('number_decimal_plus_maxdigits', `function func() { return 1.123456789012345678; }`, '1.123456789012345678')
    makeTest('number_decimal_plus_overmaxdigits', `function func() { return 1.1234567890123456789; }`, '1.123456789012345678')
    makeTest('number_decimal_plus_u32max', `function func() { return 4294967295.123; }`, '4294967295.123')
    makeTest('number_decimal_plus_u64max', `function func() { return 18446744073709551615.123456789012345678; }`, '18446744073709551615.123456789012345678')
    makeTest('number_decimal_minus', `function func() { return -1.1; }`, '-1.1')
    makeTest('number_decimal_minus2', `function func() { return -2.123; }`, '-2.123')
    makeTest('number_decimal_minus3', `function func() { return -99.999; }`, '-99.999')
    makeTest('number_decimal_minus_maxdigits', `function func() { return -1.123456789012345678; }`, '-1.123456789012345678')
    makeTest('number_decimal_minus_overmaxdigits', `function func() { return -1.1234567890123456789; }`, '-1.123456789012345678')
    makeTest('number_decimal_minus_u32min', `function func() { return -4294967295; }`, '-4294967295')
    makeTest('number_decimal_minus_u64min', `function func() { return -18446744073709551615; }`, '-18446744073709551615')
  })
  describe('exponent', function () {
    makeTest('number_exponent_zero', `function func() { return 2e0; }`, '2')
    makeTest('number_exponent_zero2', `function func() { return 0e1; }`, '0')
    makeTest('number_exponent_plus', `function func() { return -2e1; }`, '-20')
    makeTest('number_exponent_plus2', `function func() { return 2E2; }`, '200')
    makeTest('number_exponent_plus3', `function func() { return -99e12; }`, '-99000000000000')
    makeTest('number_exponent_maxdigits', `function func() { return 1.8446744073709551615e19; }`, '18446744073709551615')
    makeTest('number_exponent_minus', `function func() { return 100e-1; }`, '10')
    makeTest('number_exponent_minus2', `function func() { return -123e-2; }`, '-1.23')
    makeTest('number_exponent_minus3', `function func() { return 999e-10; }`, '0.0000000999')
    makeTest('number_exponent_minus_minditits', `function func() { return -123456789012345678e-18; }`, '-0.123456789012345678')
    makeTest('number_exponent_minus_overminditits', `function func() { return -123456789012345678e-19; }`, '-0.012345678901234567')
    makeTestError('number_exponent_decimal', `function func() { return 1e1.1; }`, 'exponent must be integer')
    makeTestError('number_exponent_decimal', `function func() { return 1e12n; }`, 'exponent must be integer')
    makeTestError('number_exponent_decimal', `function func() { return 1e12a; }`, 'undefined identifier')
    //makeTestError('number_exponent_decimal', `function func() { return 1e(12+1); }`, 'exponent must be integer',true)
  })
  describe('hex', function () {
    makeTest('number_hex_zero', `function func() { return 0x0; }`, '0')
    makeTest('number_hex_plus', `function func() { return 0X1; }`, '1')
    makeTest('number_hex_plus2', `function func() { return 0x2; }`, '2')
    makeTest('number_hex_plus3', `function func() { return 0X10; }`, '16')
    makeTest('number_hex_plus4', `function func() { return 0xff; }`, '255')
    makeTest('number_hex_plus5', `function func() { return 0xaAbBcCdDeEfF; }`, '187723572702975')
    makeTest('number_hex_plus6', `function func() { return 0X0123456789; }`, '4886718345')
    makeTest('number_hex_plus_u64max', `function func() { return 0xFFFFFFFFFFFFFFFF; }`, '18446744073709551615')
    makeTest('number_hex_minus', `function func() { return -0x1; }`, '-1')
    makeTest('number_hex_minus2', `function func() { return -0x02; }`, '-2')
    makeTest('number_hex_minus3', `function func() { return -0x99; }`, '-153')
    makeTest('number_hex_minus_u64max', `function func() { return -0xFFFFFFFFFFFFFFFF; }`, '-18446744073709551615')
    makeTestError('number_hex_invalid', `function func() { return 0xFG; }`, 'undefined identifier')
  })
  describe('binary', function () {
    makeTest('number_binary_zero', `function func() { return 0b0; }`, '0')
    makeTest('number_binary_plus', `function func() { return 0B1; }`, '1')
    makeTest('number_binary_plus2', `function func() { return 0B10; }`, '2')
    makeTest('number_binary_plus3', `function func() { return 0B11; }`, '3')
    makeTest('number_binary_plus4', `function func() { return 0B01; }`, '1')
    makeTest('number_binary_plus5', `function func() { return 0B00; }`, '0')
    makeTest('number_binary_plus6', `function func() { return 0b00011011; }`, '27')
    makeTest('number_binary_plus_u64max', `function func() { return 0b1111111111111111111111111111111111111111111111111111111111111111; }`, '18446744073709551615')
    makeTest('number_binary_minus', `function func() { return -0b1; }`, '-1')
    makeTest('number_binary_plus2', `function func() { return -0B10; }`, '-2')
    makeTest('number_binary_plus3', `function func() { return -0B11; }`, '-3')
    makeTest('number_binary_minus_u64max', `function func() { return -0b1111111111111111111111111111111111111111111111111111111111111111; }`, '-18446744073709551615')
    makeTestError('number_binary_invalid', `function func() { return 0b2; }`, 'invalid binary')
    makeTestError('number_binary_invalid2', `function func() { return 0b1a; }`, 'undefined identifier')
  })
  describe('octal', function () {
    makeTest('number_octal_zero', `function func() { return 0o0; }`, '0')
    makeTest('number_octal_plus', `function func() { return 0O1; }`, '1')
    makeTest('number_octal_plus2', `function func() { return 0o10; }`, '8')
    makeTest('number_octal_plus3', `function func() { return 0O76543210; }`, '16434824')
    makeTest('number_octal_plus4', `function func() { return 0O01234567; }`, '342391')
    makeTest('number_octal_plus_u64max', `function func() { return 0o1777777777777777777777; }`, '18446744073709551615')
    makeTest('number_octal_minus', `function func() { return -0o1; }`, '-1')
    makeTest('number_octal_plus2', `function func() { return -0O11; }`, '-9')
    makeTest('number_octal_plus3', `function func() { return -0O76543210; }`, '-16434824')
    makeTest('number_octal_minus_u64max', `function func() { return -0o1777777777777777777777; }`, '-18446744073709551615')
    makeTestError('number_octal_invalid', `function func() { return 0o9; }`, 'invalid octal')
    makeTestError('number_octal_invalid2', `function func() { return 0o3f; }`, 'undefined identifier')
  })
  describe('string', function () {
    makeTest('string_empty', `function func() { return ''; }`, '')
    makeTest('string_empty2', `function func() { return ""; }`, '')
    makeTest('string_space', `function func() { return ' '; }`, ' ')
    makeTest('string_alpabet', `function func() { return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'; }`, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
    makeTest('string_number', `function func() { return '1234567890'; }`, '1234567890')
    makeTest('string_symbol', `function func() { return '!\\"#$%&\\'()*+,-./:;<=>?@[\\]^_{|}\\~'; }`, `!\\"#$%&\\'()*+,-./:;<=>?@[\\]^_{|}\\~`)
    makeTest('string_escape', `function func() { return '\\n\\r\\t\\b\\f\\"\\'\\\\'; }`, `\\n\\r\\t\\b\\f\\"\\'\\\\`)
    makeTest('string_number', `function func() { return '1' }`, `1`)
    makeTest('string_number_hex', `function func() { return '0x1' }`, `0x1`)
    makeTest('string_number_binary', `function func() { return '0b1' }`, `0b1`)
    makeTest('string_number_octal', `function func() { return '0o1' }`, `0o1`)
    makeTest('string_number_octal_literal', `function func() { return '01234567'; }`, '01234567')
    makeTestError('string_multibytes_alphabet', `function func() { return 'abcｓ'; }`, 'unknown char')
    makeTestError('string_multibytes_space', `function func() { return '123　'; }`, 'unknown char')
    makeTestError('string_multibytes_jp', `function func() { return '#あ'; }`, 'unknown char')
    makeTestError('string_eol', `function func() { return 'abc; }`, 'unterminated string')
    makeTestError('string_lf', `function func() { return 'abc
    '; }`, 'unterminated string')
  })
  describe('bool', function () {
    makeTest('bool_true', `function func() { return true; }`, 'true')
    makeTest('bool_false', `function func() { return false; }`, 'false')
    makeTest('bool_true_minus', `function func() { return -true; }`, '-1')
    makeTest('bool_false_minus', `function func() { return -false; }`, '0')
    makeTestError('bool_false_minus', `function func() { return truefalse; }`, 'undefined identifier')
  })
});