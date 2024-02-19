import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'
import { makeRunContext } from '../scripts/runContext'

describe('JSFunctionTest', function () {
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
  
  before(async function() {
    await loadFixture(deployFixture);
  });

  after(async function() {
    console.log(`GAS TOTAL: ${gasTotal}`)
  })

  describe('recursive', function () {
    makeTest('recursive', `function func(count=0, res='') {
      if (count > 3) {
        return res;
      } else {
        res += count;
        return func(++count, res);
      }
    }`, '0123')
  })
  
});