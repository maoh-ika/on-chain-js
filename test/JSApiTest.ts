import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'

describe('JSApiTest', function () {
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

  async function parseSignature(code: string) {
    const measure = await loadFixture(deployFixture);
    const res = await measure.measureParseSignature(proxyAddress, code, { gasLimit: gasLimit })
    return { sig: res[0], gas: +res[1] }
  }

  async function traceDependencies(code: string) {
    const measure = await loadFixture(deployFixture);
    const res = await measure.measureTraceDependencies(proxyAddress, code, { identifiers: [], args: [], startNodeIndex: 0 }, { gasLimit: gasLimit })
    return { contrib: res[0], gas: +res[1] }
  }
  
  function makeTestError(name: string, code: string, errMsg: string, only: boolean=false) {
    const testFunc = only ? it.only : it
    testFunc(`${name}`, async function () {
      try {
        await traceDependencies(code)
        assert.fail()
      } catch (err) {
        assert.throws(function() { throw err }, Error, errMsg)
      }
    })
  }
  
  let gasTotal = 0

  before(async function() {
    await loadFixture(deployFixture);
  });

  after(async function() {
    console.log(`GAS TOTAL: ${gasTotal}`)
  })

  describe('parserSignature', async function () {
    it('args_zero', async function() {
      const code = 'function func() {}'
      const { sig, gas } = await parseSignature(code)
      console.log(`args_zero: ${gas}`)
      gasTotal += gas;
      expect(sig.name).to.equal('func');
      expect(sig.args.length).to.equal(0);
    })
    it('args_1', async function() {
      const code = 'function func(arg1) {}'
      const { sig, gas } = await parseSignature(code)
      console.log(`args_1: ${gas}`)
      gasTotal += gas;
      expect(sig.name).to.equal('func');
      expect(sig.args.length).to.equal(1);
      expect(sig.args[0]).to.equal('arg1');
    })
    it('args_2', async function() {
      const code = 'function func(arg1, arg2) {}'
      const { sig, gas } = await parseSignature(code)
      console.log(`args_1: ${gas}`)
      gasTotal += gas;
      expect(sig.name).to.equal('func');
      expect(sig.args.length).to.equal(2);
      expect(sig.args[0]).to.equal('arg1');
      expect(sig.args[1]).to.equal('arg2');
    })
    it('args_default_1', async function() {
      const code = 'function func(arg1=1) {}'
      const { sig, gas } = await parseSignature(code)
      console.log(`args_default_1: ${gas}`)
      gasTotal += gas;
      expect(sig.name).to.equal('func');
      expect(sig.args.length).to.equal(1);
      expect(sig.args[0]).to.equal('arg1');
    })
    it('args_default_2', async function() {
      const code = 'function func(arg1=1, arg2=2) {}'
      const { sig, gas } = await parseSignature(code)
      console.log(`args_default_2: ${gas}`)
      gasTotal += gas;
      expect(sig.name).to.equal('func');
      expect(sig.args.length).to.equal(2);
      expect(sig.args[0]).to.equal('arg1');
      expect(sig.args[1]).to.equal('arg2');
    })
  })
  describe('parseDependencies', async function () {
    it('none', async function() {
      const code = 'function func() {}'
      const { contrib, gas } = await traceDependencies(code)
      console.log(`none: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(0);
      expect(contrib.exeTokenDependees.length).to.equal(0);
    })
    it('token', async function() {
      const code = 'function func() { executeToken(10) }'
      const { contrib, gas } = await traceDependencies(code)
      console.log(`token: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(0);
      expect(contrib.exeTokenDependees.length).to.equal(1);
      expect(contrib.exeTokenDependees[0]).to.equal(10);
    })
    it('token_2', async function() {
      const code = `function func() {
        executeToken(10);
        executeToken(99, 2);
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`token_2: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(0);
      expect(contrib.exeTokenDependees.length).to.equal(2);
      expect(contrib.exeTokenDependees[0]).to.equal(10);
      expect(contrib.exeTokenDependees[1]).to.equal(99);
    })
    it('contract', async function() {
      const code = `
      function snippetJS(code="function run() { return 'SnippetJS'; }") {
        return staticcallContract(
          '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1',
          'interpretToString(string)',
          { type: "string" },
          code);
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`contract: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(1);
      expect(contrib.contractDependees[0]).to.equal('0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1');
      expect(contrib.exeTokenDependees.length).to.equal(0);
    })
    it('contract_2', async function() {
      const code = `
      function snippetJS(code="function run() { return 'SnippetJS'; }") {
        var a = staticcallContract(
          '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1',
          'interpretToString(string)',
          { type: "string" },
          code);
        var b = staticcallContract(
          '0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44',
          'interpretToString(string)',
          { type: "string" },
          code);
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`contract_2: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(2);
      expect(contrib.contractDependees[0]).to.equal('0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1');
      expect(contrib.contractDependees[1]).to.equal('0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44');
      expect(contrib.exeTokenDependees.length).to.equal(0);
    })
    it('token_contract', async function() {
      const code = `function func() {
        executeToken(10)
        var a = staticcallContract(
          '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1',
          'interpretToString(string)',
          { type: "string" },
          '');
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`token: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(1);
      expect(contrib.contractDependees[0]).to.equal('0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1');
      expect(contrib.exeTokenDependees.length).to.equal(1);
      expect(contrib.exeTokenDependees[0]).to.equal(10);
    })
    it('token_contract_dynamic', async function() {
      const code = `function func() {
        var tokenId = 1;
        executeToken(tokenId);
        var addr = '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1';
        var a = staticcallContract(
          addr,
          'interpretToString(string)',
          { type: "string" },
          '');
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`token: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(1);
      expect(contrib.contractDependees[0]).to.equal('0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1');
      expect(contrib.exeTokenDependees.length).to.equal(1);
      expect(contrib.exeTokenDependees[0]).to.equal(1);
    })
    it('token_contract_2', async function() {
      const code = `function func() {
        var tokenId = 1;
        executeToken(tokenId);
        executeToken(0);
        var addr = '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1';
        staticcallContract(
          addr,
          'interpretToString(string)',
          { type: "string" },
          '');
        staticcallContract(
          '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
          'returnToken()',
          undefined);
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`token: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(2);
      expect(contrib.contractDependees[0]).to.equal('0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0');
      expect(contrib.contractDependees[1]).to.equal('0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1');
      expect(contrib.exeTokenDependees.length).to.equal(2);
      expect(contrib.exeTokenDependees[0]).to.equal(0);
      expect(contrib.exeTokenDependees[1]).to.equal(1);
    })
    it('token_contract_dup', async function() {
      const code = `function func() {
        var tokenId = 1;
        executeToken(tokenId);
        executeToken(1);
        var addr = '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1';
        staticcallContract(
          addr,
          'interpretToString(string)',
          { type: "string" },
          '');
        staticcallContract(
          '0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1',
          'interpretToString(string)',
          { type: "string" },
          '');
      }`
      const { contrib, gas } = await traceDependencies(code)
      console.log(`token: ${gas}`)
      gasTotal += gas;
      expect(contrib.contractDependees.length).to.equal(1);
      expect(contrib.contractDependees[0]).to.equal('0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1');
      expect(contrib.exeTokenDependees.length).to.equal(1);
      expect(contrib.exeTokenDependees[0]).to.equal(1);
    })
  })
});