import { ethers, network } from "hardhat";
import { makeEmptyContext } from './runContext'
import lexerAbi from '../artifacts/contracts/lexer/JSLexer.sol/JSLexer'
import astAbi from '../artifacts/contracts/ast/AstBuilder.sol/AstBuilder'
import interpreterAbi from '../artifacts/contracts/interpreter/JSInterpreter.sol/JSInterpreter'
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from './addresses'


async function main() {
  const lexerAddress = addresses[network.name]['lexer']['JSLexer']
  const astAddress = addresses[network.name]['astBuilder']['AstBuilder']
  const interpreterAddress = addresses[network.name]['interpreter']['JSInterpreter']
  const measuerAddress = addresses[network.name]['utils']['MeasureGas']
  console.log(`JSLexer: ${lexerAddress}`)
  console.log(`AstBuilder: ${astAddress}`)
  console.log(`JSInterpreter: ${astAddress}`)
  console.log(`MeasureGas: ${measuerAddress}`)
  const gasLimit = 900000000
  const lexer = new ethers.Contract(
    lexerAddress,
    lexerAbi.abi,
    ethers.provider
  )
  const astBuilder = new ethers.Contract(
    astAddress,
    astAbi.abi,
    ethers.provider
  )
  const interpreter = new ethers.Contract(
    interpreterAddress,
    interpreterAbi.abi,
    ethers.provider
  )
  
  const measure = new ethers.Contract(
    measuerAddress,
    measureAbi.abi,
    ethers.provider
  )
  
  const state = makeEmptyContext()

  const tests = {
    'insertSort':
      `function insertSort() {
        var arr = [2,1,7,3];
        for (var i = 0; i < 4; ++i) {
          var val = arr[i];
          var pos = i - 1;
          for (; pos >= 0 && arr[pos] > val; --pos) {
            arr[pos + 1] = arr[pos];
          }
          arr[pos + 1] = val;
        }
        return arr;
      }`,
    'greedySearch': `
      function greedySearch(positions=[1,2,3,4,5,6,7,8], minLength=50, minCutTimes=1, L=100) {
        var length = 0;
        var cutTimes = 0;
        for (var i = 0; i <= positions.length; i++) {
          var delta;
          if (i === 0) {
            delta = positions[i];
          } else if (i === positions.length) {
            delta = L - positions[i - 1];
          } else {
            delta = positions[i] - positions[i - 1];
          }
          length += delta;
      
          if (length >= minLength) {
            length = 0;
            cutTimes++;
          }
      
          if (cutTimes > minCutTimes) { return true };
        }
        return false;
      }`,
  }

  for (let name in tests) {
    console.log(`[${name}]`)
    let b = Date.now()
    let res = await measure.measureLexer(lexer.address, tests[name], {
      gasLimit: gasLimit
    })
    console.log(`  tokenize: ${(Date.now() - b)/1000} s, ${res[0]} gas`)
    b = Date.now()
    res = await measure.measureAst(res[1], astBuilder.address, {
      gasLimit: gasLimit
    })
    console.log(`  build: ${(Date.now() - b)/1000} s, ${res[0]} gas`)
    b = Date.now()
    const interpretGas = await measure.measureInterpreter(res[1], interpreter.address, state, {
      gasLimit: gasLimit
    })
    console.log(`  interpret: ${(Date.now() - b)/1000} s, ${interpretGas} gas`)

  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
