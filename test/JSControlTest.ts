import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'
import { makeRunContext } from '../scripts/runContext'

describe('JSControlTest', function () {
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

  describe('for_in', function () {
    makeTest('for_in', `function func() {
      var obj = {int:1, int2:3};
      var res = 0;
      for (var key in obj) { res += obj[key]; }
      return res;
    }`,
    '4')
  })
  
});