import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'
import { makeRunContext } from '../scripts/runContext'

describe('JSBiOpTest', function () {
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

  describe('addition', function () {
    makeTest('addition_integer_plus_zero', `function func() { return 0 + 0; }`, '0')
    makeTest('addition_integer_plus_1dig', `function func() { return 1 + 2; }`, '3')
    makeTest('addition_integer_plus_2dig', `function func() { return 10 + 99; }`, '109')
    makeTest('addition_integer_plus_u64max', `function func() { return 18446744073709551614 + 1; }`, '18446744073709551615')
    makeTest('addition_integer_minus_zero', `function func() { return 0 + (-0); }`, '0')
    makeTest('addition_integer_minus_1dig', `function func() { return 1 + (-2); }`, '-1')
    makeTest('addition_integer_minus_2dig', `function func() { return (-10) + 99; }`, '89')
    makeTest('addition_integer_minus_u64max', `function func() { return (-18446744073709551614) + (-1); }`, '-18446744073709551615')
    makeTest('addition_decimal_plus_zero', `function func() { return 0.0 + .0; }`, '0')
    makeTest('addition_decimal_plus_1dig', `function func() { return 1.23 + 2.01; }`, '3.24')
    makeTest('addition_decimal_plus_2dig', `function func() { return 10.10 + 99.00099; }`, '109.10099')
    makeTest('addition_decimal_plus_maxdigits', `function func() { return 1.123456789012345678 + 1.000000000000000001; }`, '2.123456789012345679')
    makeTest('addition_decimal_plus_overmaxdigits', `function func() { return 1.123456789012345678 + 1.0000000000000000001; }`, '2.123456789012345678')
    makeTest('addition_decimal_minus_zero', `function func() { return (-0.0) + (-.0); }`, '0')
    makeTest('addition_decimal_minus_1dig', `function func() { return 0.01 + (-2); }`, '-1.99')
    makeTest('addition_decimal_minus_2dig', `function func() { return (-.10) + 99; }`, '98.9')
    makeTest('addition_decimal_minus_maxdigits', `function func() { return 1.123456789012345678 + (-1.000000000000000001); }`, '0.123456789012345677')
    makeTest('addition_decimal_minus_overmaxdigits', `function func() { return 1.123456789012345678 + (-1.0000000000000000001); }`, '0.123456789012345678')
    makeTest('addition_exponent_plus_zero', `function func() { return 0e0 + 10e0; }`, '10')
    makeTest('addition_exponent_plus_1dig', `function func() { return 1e1 + 2e1; }`, '30')
    makeTest('addition_exponent_plus_2dig', `function func() { return 3e10 + 4e11; }`, '430000000000')
    makeTest('addition_exponent_plus_maxdigits', `function func() { return 1.844674407370955161e18 + 1.000000000000000001e18; }`, '2844674407370955162')
    makeTest('addition_exponent_minus_zero', `function func() { return 0e-0 + (-0e0); }`, '0')
    makeTest('addition_exponent_minus_1dig', `function func() { return 5e1 + 5e-2; }`, '50.05')
    makeTest('addition_exponent_minus_2dig', `function func() { return (-1e-10) + 9e9; }`, '8999999999.9999999999')
    makeTest('addition_exponent_minus_u64max', `function func() { return 123456789012345678e-18 + (-1e0); }`, '-0.876543210987654322')
    makeTest('addition_str_str', `function func() { return 'str1' + 'str2'; }`, 'str1str2')
    makeTest('addition_str_number', `function func() { return 'str1' + 2; }`, 'str12')
    makeTest('addition_str_bool', `function func() { return 'str1' + true; }`, 'str1true')
    makeTest('addition_str_array', `function func() { return 'str1' + [1,2]; }`, 'str11,2')
    makeTest('addition_str_object', `function func() { return 'str1' + {int:1}; }`, 'NaN')
    makeTest('addition_numberStr_numberStr', `function func() { return '1' + '2'; }`, '12')
    makeTest('addition_numberStr_numberStr2', `function func() { return '-1' + '-2'; }`, '-1-2')
    makeTest('addition_numberStr_number', `function func() { return '1' + 2; }`, '12')
    makeTest('addition_numberStr_number2', `function func() { return '1' + (-2); }`, '1-2')
    makeTest('addition_numberStr_number3', `function func() { return '-1' + 2; }`, '-12')
    makeTest('addition_numberStr_number4', `function func() { return '-1' + (-2); }`, '-1-2')
    makeTest('addition_number_numberStr', `function func() { return 1 + '2'; }`, '12')
    makeTest('addition_number_numberStr2', `function func() { return -1 + '2'; }`, '-12')
    makeTest('addition_number_numberStr3', `function func() { return 1 + '-2'; }`, '1-2')
    makeTest('addition_number_numberStr4', `function func() { return -1 + '-2'; }`, '-1-2')
    makeTest('addition_numberStr_bool', `function func() { return '123' + true; }`, '123true')
    makeTest('addition_bool_numberStr', `function func() { return false + '123'; }`, 'false123')
  })
  
  describe('subtraction', function () {
    makeTest('subtraction_integer_plus_zero', `function func() { return 0 - 0; }`, '0')
    makeTest('subtraction_integer_plus_1dig', `function func() { return 1 - 2; }`, '-1')
    makeTest('subtraction_integer_plus_2dig', `function func() { return 10 - 99; }`, '-89')
    makeTest('subtraction_integer_plus_u64max', `function func() { return 18446744073709551615 - 1; }`, '18446744073709551614')
    makeTest('subtraction_integer_minus_zero', `function func() { return 0 - (-0); }`, '0')
    makeTest('subtraction_integer_minus_1dig', `function func() { return 1 - (-2); }`, '3')
    makeTest('subtraction_integer_minus_2dig', `function func() { return (-10) - 99; }`, '-109')
    makeTest('subtraction_integer_minus_u64max', `function func() { return (-18446744073709551614) - (1); }`, '-18446744073709551615')
    makeTest('subtraction_decimal_plus_zero', `function func() { return 0.0 - .0; }`, '0')
    makeTest('subtraction_decimal_plus_1dig', `function func() { return 1.23 - 2.01; }`, '-0.78')
    makeTest('subtraction_decimal_plus_2dig', `function func() { return 10.10 - 99.00099; }`, '-88.90099')
    makeTest('subtraction_decimal_plus_maxdigits', `function func() { return 1.123456789012345678 - 1.000000000000000001; }`, '0.123456789012345677')
    makeTest('subtraction_decimal_plus_overmaxdigits', `function func() { return 1.123456789012345678 - 1.0000000000000000001; }`, '0.123456789012345678')
    makeTest('subtraction_decimal_minus_zero', `function func() { return (-0.0) - (-.0); }`, '0')
    makeTest('subtraction_decimal_minus_1dig', `function func() { return 0.01 - (-2); }`, '2.01')
    makeTest('subtraction_decimal_minus_2dig', `function func() { return (-.10) - 99; }`, '-99.1')
    makeTest('subtraction_decimal_minus_maxdigits', `function func() { return 1.123456789012345678 - (-1.000000000000000001); }`, '2.123456789012345679')
    makeTest('subtraction_decimal_minus_overmaxdigits', `function func() { return 1.123456789012345678 - (-1.0000000000000000001); }`, '2.123456789012345678')
    makeTest('subtraction_exponent_plus_zero', `function func() { return 0e0 - 10e0; }`, '-10')
    makeTest('subtraction_exponent_plus_1dig', `function func() { return 1e1 - 2e1; }`, '-10')
    makeTest('subtraction_exponent_plus_2dig', `function func() { return 3e10 - 4e11; }`, '-370000000000')
    makeTest('subtraction_exponent_plus_maxdigits', `function func() { return 1.844674407370955161e18 - 1.000000000000000001e18; }`, '844674407370955160')
    makeTest('subtraction_exponent_minus_zero', `function func() { return 0e-0 - (-0e0); }`, '0')
    makeTest('subtraction_exponent_minus_1dig', `function func() { return 5e1 - 5e-2; }`, '49.95')
    makeTest('subtraction_exponent_minus_2dig', `function func() { return (-1e-10) - 9e9; }`, '-9000000000.0000000001')
    makeTest('subtraction_exponent_minus_u64max', `function func() { return 123456789012345678e-18 - (-1e0); }`, '1.123456789012345678')
    makeTest('subtraction_str_str', `function func() { return 'str1' - 'str2'; }`, 'NaN')
    makeTest('subtraction_str_number', `function func() { return 'str1' - 2; }`, 'NaN')
    makeTest('subtraction_str_bool', `function func() { return 'str1' - true; }`, 'NaN')
    makeTest('subtraction_str_array', `function func() { return 'str1' - [1,2]; }`, 'NaN')
    makeTest('subtraction_str_object', `function func() { return 'str1' + {int:1}; }`, 'NaN')
    makeTest('substraction_numberStr_numberStr', `function func() { return '123' - '-23'; }`, '146')
    makeTest('substraction_numberStr_numberStr2', `function func() { return '-1' - '-2'; }`, '1')
    makeTest('substraction_numberStr_number', `function func() { return '1' - 2; }`, '-1')
    makeTest('substraction_numberStr_number2', `function func() { return '1' - (-2); }`, '3')
    makeTest('substraction_numberStr_number3', `function func() { return '-1' - 2; }`, '-3')
    makeTest('substraction_numberStr_number4', `function func() { return '-1' - (-2); }`, '1')
    makeTest('substraction_number_numberStr', `function func() { return 1 - '2'; }`, '-1')
    makeTest('substraction_number_numberStr2', `function func() { return -1 - '2'; }`, '-3')
    makeTest('substraction_number_numberStr3', `function func() { return 1 - '-2'; }`, '3')
    makeTest('substraction_number_numberStr4', `function func() { return -1 - '-2'; }`, '1')
    makeTest('substraction_numberStr_bool', `function func() { return '123' - true; }`, '122')
    makeTest('substraction_bool_numberStr', `function func() { return false - '123'; }`, '-123')
  })
 
  describe('multiplication', function () {
    makeTest('multiplication_integer_plus_zero', `function func() { return 0 * 0; }`, '0')
    makeTest('multiplication_integer_plus_1dig', `function func() { return 1 * 2; }`, '2')
    makeTest('multiplication_integer_plus_2dig', `function func() { return 10 * 99; }`, '990')
    makeTest('multiplication_integer_plus_u64max', `function func() { return 18446744073709551615 * 1; }`, '18446744073709551615')
    makeTest('multiplication_integer_minus_zero', `function func() { return 0 * (-0); }`, '0')
    makeTest('multiplication_integer_minus_1dig', `function func() { return 1 * (-2); }`, '-2')
    makeTest('multiplication_integer_minus_2dig', `function func() { return (-10) * 99; }`, '-990')
    makeTest('multiplication_integer_minus_u64max', `function func() { return (-18446744073709551614) * (1); }`, '-18446744073709551614')
    makeTest('multiplication_decimal_plus_zero', `function func() { return 0.0 * .0; }`, '0')
    makeTest('multiplication_decimal_plus_1dig', `function func() { return 1.23 * 2.01; }`, '2.4723')
    makeTest('multiplication_decimal_plus_2dig', `function func() { return 10.10 * 99.00099; }`, '999.909999')
    makeTest('multiplication_decimal_plus_maxdigits', `function func() { return 1.123456789012345678 * 1.000000000000000001; }`, '1.123456789012345679')
    makeTest('multiplication_decimal_plus_overmaxdigits', `function func() { return 1.123456789012345678 * 1.0000000000000000001; }`, '1.123456789012345678')
    makeTest('multiplication_decimal_minus_zero', `function func() { return (-0.0) * (-.0); }`, '0')
    makeTest('multiplication_decimal_minus_1dig', `function func() { return 0.01 * (-2); }`, '-0.02')
    makeTest('multiplication_decimal_minus_2dig', `function func() { return (-.10) * 99; }`, '-9.9')
    makeTest('multiplication_exponent_plus_zero', `function func() { return 0e0 * 10e0; }`, '0')
    makeTest('multiplication_exponent_plus_1dig', `function func() { return 1e1 * 2e1; }`, '200')
    makeTest('multiplication_exponent_plus_2dig', `function func() { return 3e10 * 4e11; }`, '12000000000000000000000')
    makeTest('multiplication_exponent_minus_zero', `function func() { return 0e-0 * (-0e0); }`, '0')
    makeTest('multiplication_exponent_minus_1dig', `function func() { return 5e1 * 5e-2; }`, '2.5')
    makeTest('multiplication_exponent_minus_2dig', `function func() { return (-1e-10) * 9e9; }`, '-0.9')
    makeTest('multiplication_exponent_minus_u64max', `function func() { return 123456789012345678e-18 * (-1e0); }`, '-0.123456789012345678')
    makeTest('multiplication_str_str', `function func() { return 'str1' * 'str2'; }`, 'NaN')
    makeTest('multiplication_str_number', `function func() { return 'str1' * 2; }`, 'NaN')
    makeTest('multiplication_str_bool', `function func() { return 'str1' * true; }`, 'NaN')
    makeTest('multiplication_str_array', `function func() { return 'str1' * [1,2]; }`, 'NaN')
    makeTest('multiplication_str_object', `function func() { return 'str1' * {int:1}; }`, 'NaN')
    makeTest('multiplication_numberStr_numberStr', `function func() { return '123' * '-23'; }`, '-2829')
    makeTest('multiplication_numberStr_numberStr2', `function func() { return '-1' * '-2'; }`, '2')
    makeTest('multiplication_numberStr_number', `function func() { return '1' * 2; }`, '2')
    makeTest('multiplication_numberStr_number2', `function func() { return '1' * (-2); }`, '-2')
    makeTest('multiplication_numberStr_number3', `function func() { return '-1' * 2; }`, '-2')
    makeTest('multiplication_numberStr_number4', `function func() { return '-1' * (-2); }`, '2')
    makeTest('multiplication_number_numberStr', `function func() { return 1 * '2'; }`, '2')
    makeTest('multiplication_number_numberStr2', `function func() { return -1 * '2'; }`, '-2')
    makeTest('multiplication_number_numberStr3', `function func() { return 1 * '-2'; }`, '-2')
    makeTest('multiplication_number_numberStr4', `function func() { return -1 * '-2'; }`, '2')
    makeTest('multiplication_numberStr_bool', `function func() { return '123' * true; }`, '123')
    makeTest('multiplication_bool_numberStr', `function func() { return false * '123'; }`, '0')
  })
  
  describe('division', function () {
    makeTest('division_integer_plus_zero', `function func() { return 0 / 0; }`, 'NaN')
    makeTest('division_integer_plus_1dig', `function func() { return 1 / 2; }`, '0.5')
    makeTest('division_integer_plus_2dig', `function func() { return 10 / 99; }`, '0.10101010101010101')
    makeTest('division_integer_plus_u64max', `function func() { return 18446744073709551615 / 1; }`, '18446744073709551615')
    makeTest('division_integer_minus_zero', `function func() { return 0 / (-0); }`, 'NaN')
    makeTest('division_integer_minus_1dig', `function func() { return 1 / (-2); }`, '-0.5')
    makeTest('division_integer_minus_2dig', `function func() { return (-10) / 99; }`, '-0.10101010101010101')
    makeTest('division_integer_minus_u64max', `function func() { return (-18446744073709551614) / (1); }`, '-18446744073709551614')
    makeTest('division_decimal_plus_zero', `function func() { return 0.0 / .0; }`, 'NaN')
    makeTest('division_decimal_plus_1dig', `function func() { return 1.23 / 2.01; }`, '0.611940298507462686')
    makeTest('division_decimal_plus_2dig', `function func() { return 10.10 / 99.00099; }`, '0.102019181828383736')
    makeTest('division_decimal_plus_maxdigits', `function func() { return 0.000000000000000001 / 0.000000000000000005; }`, '0.2')
    makeTest('division_decimal_plus_overmaxdigits', `function func() { return 1.123456789012345678 / 1.0000000000000000001; }`, '1.123456789012345678')
    makeTest('division_decimal_minus_zero', `function func() { return (-0.0) / (-.0); }`, 'NaN')
    makeTest('division_decimal_minus_1dig', `function func() { return 0.01 / (-2); }`, '-0.005')
    makeTest('division_decimal_minus_2dig', `function func() { return (-.10) / 99; }`, '-0.00101010101010101')
    makeTest('division_exponent_plus_zero', `function func() { return 0e0 / 10e0; }`, '0')
    makeTest('division_exponent_plus_1dig', `function func() { return 1e1 / 2e1; }`, '0.5')
    makeTest('division_exponent_plus_2dig', `function func() { return 3e10 / 4e11; }`, '0.075')
    makeTest('division_exponent_minus_zero', `function func() { return 0e-0 / (-0e0); }`, 'NaN')
    makeTest('division_exponent_minus_1dig', `function func() { return 5e1 / 5e-2; }`, '1000')
    makeTest('division_exponent_minus_2dig', `function func() { return (-1e-10) / 9e9; }`, '0')
    makeTest('division_exponent_minus_u64max', `function func() { return 123456789012345e-18 / (-1e0); }`, '-0.000123456789012345')
    makeTest('division_str_str', `function func() { return 'str1' / 'str2'; }`, 'NaN')
    makeTest('division_str_number', `function func() { return 'str1' / 2; }`, 'NaN')
    makeTest('division_str_bool', `function func() { return 'str1' / true; }`, 'NaN')
    makeTest('division_str_array', `function func() { return 'str1' / [1,2]; }`, 'NaN')
    makeTest('division_str_object', `function func() { return 'str1' / {int:1}; }`, 'NaN')
    makeTest('division_numberStr_numberStr', `function func() { return '123' / '-23'; }`, '-5.347826086956521739')
    makeTest('division_numberStr_numberStr2', `function func() { return '-1' / '-2'; }`, '0.5')
    makeTest('division_numberStr_number', `function func() { return '1' / 2; }`, '0.5')
    makeTest('division_numberStr_number2', `function func() { return '1' / (-2); }`, '-0.5')
    makeTest('division_numberStr_number3', `function func() { return '-1' / 2; }`, '-0.5')
    makeTest('division_numberStr_number4', `function func() { return '-1' / (-2); }`, '0.5')
    makeTest('division_number_numberStr', `function func() { return 1 / '2'; }`, '0.5')
    makeTest('division_number_numberStr2', `function func() { return -1 / '2'; }`, '-0.5')
    makeTest('division_number_numberStr3', `function func() { return 1 / '-2'; }`, '-0.5')
    makeTest('division_number_numberStr4', `function func() { return -1 / '-2'; }`, '0.5')
    makeTest('division_numberStr_bool', `function func() { return '123' / true; }`, '123')
    makeTest('division_bool_numberStr', `function func() { return false / '123'; }`, '0')
  })
  
  describe('remainder', function () {
    makeTest('remainder_integer_plus_zero', `function func() { return 0 % 0; }`, 'NaN')
    makeTest('remainder_integer_plus_1dig', `function func() { return 1 % 2; }`, '1')
    makeTest('remainder_integer_plus_2dig', `function func() { return 185 % 99; }`, '86')
    makeTest('remainder_integer_plus_u64max', `function func() { return 18446744073709551615 % 1; }`, '0')
    makeTest('remainder_integer_minus_zero', `function func() { return 0 % (-0); }`, 'NaN')
    makeTest('remainder_integer_minus_1dig', `function func() { return 1 % (-2); }`, '1')
    makeTest('remainder_integer_minus_2dig', `function func() { return (-10) % 99; }`, '-10')
    makeTest('remainder_integer_minus_u64max', `function func() { return (-18446744073709551614) % (1); }`, '0')
    makeTest('remainder_decimal_plus_zero', `function func() { return 0.0 % .0; }`, 'NaN')
    makeTest('remainder_decimal_plus_1dig', `function func() { return 4.02  % 2.01; }`, '0')
    makeTest('remainder_decimal_plus_2dig', `function func() { return 233.10 % 99.00099; }`, '35.09802')
    makeTest('remainder_decimal_plus_maxdigits', `function func() { return 0.000000000000000001 % 0.000000000000000005; }`, '0.000000000000000001')
    makeTest('remainder_decimal_plus_overmaxdigits', `function func() { return 1.123456789012345678 % 1.0000000000000000001; }`, '0.123456789012345678')
    makeTest('remainder_decimal_minus_zero', `function func() { return (-0.0) % (-.0); }`, 'NaN')
    makeTest('remainder_decimal_minus_1dig', `function func() { return 0.01 % (-2); }`, '0.01')
    makeTest('remainder_decimal_minus_2dig', `function func() { return (-.10) % 99; }`, '-0.1')
    makeTest('remainder_exponent_plus_zero', `function func() { return 0e0 % 10e0; }`, '0')
    makeTest('remainder_exponent_plus_1dig', `function func() { return 1e1 % 2e1; }`, '10')
    makeTest('remainder_exponent_plus_2dig', `function func() { return 5e10 % 4e11; }`, '50000000000')
    makeTest('remainder_exponent_minus_zero', `function func() { return 0e-0 % (-0e0); }`, 'NaN')
    makeTest('remainder_exponent_minus_1dig', `function func() { return 5e1 % 500e-2; }`, '0')
    makeTest('remainder_exponent_minus_2dig', `function func() { return (-1e-10) % 9e9; }`, '-0.0000000001')
    makeTest('remainder_exponent_minus_u64max', `function func() { return 123456789012345e-18 % (-1e0); }`, '0.000123456789012345')
    makeTest('remainder_str_str', `function func() { return 'str1' % 'str2'; }`, 'NaN')
    makeTest('remainder_str_number', `function func() { return 'str1' % 2; }`, 'NaN')
    makeTest('remainder_str_bool', `function func() { return 'str1' % true; }`, 'NaN')
    makeTest('remainder_str_array', `function func() { return 'str1' % [1,2]; }`, 'NaN')
    makeTest('remainder_str_object', `function func() { return 'str1' % {int:1}; }`, 'NaN')
    makeTest('remainder_numberStr_numberStr', `function func() { return '123' % '-23'; }`, '8')
    makeTest('remainder_numberStr_numberStr2', `function func() { return '-1' % '-2'; }`, '-1')
    makeTest('remainder_numberStr_number', `function func() { return '1' % 2; }`, '1')
    makeTest('remainder_numberStr_number2', `function func() { return '1' % (-2); }`, '1')
    makeTest('remainder_numberStr_number3', `function func() { return '-1' % 2; }`, '-1')
    makeTest('remainder_numberStr_number4', `function func() { return '-1' % (-2); }`, '-1')
    makeTest('remainder_number_numberStr', `function func() { return 1 % '2'; }`, '1')
    makeTest('remainder_number_numberStr2', `function func() { return -1 % '2'; }`, '-1')
    makeTest('remainder_number_numberStr3', `function func() { return 1 % '-2'; }`, '1')
    makeTest('remainder_number_numberStr4', `function func() { return -1 % '-2'; }`, '-1')
    makeTest('remainder_numberStr_bool', `function func() { return '123' % true; }`, '0')
    makeTest('remainder_bool_numberStr', `function func() { return false % '123'; }`, '0')
  })
  
  describe('access', function () {
  })
  describe('assignment', function () {
  })
  
  describe('update', function () {
  })
});