import { ethers } from "hardhat";
import lexerAbi from '../artifacts/contracts/lexer/JSLexer.sol/JSLexer'
import astAbi from '../artifacts/contracts/ast/AstBuilder.sol/AstBuilder'
import interpreterAbi from '../artifacts/contracts/interpreter/JSInterpreter.sol/JSInterpreter'
import { makeRunContext } from './runContext'

async function main() {
  const lexerAddress = '0x9A676e781A523b5d0C0e43731313A708CB607508'
  const astAddress = '0x3Aa5ebB10DC797CAC828524e59A333d0A371443c'
  const interpreterAddress = '0xc3e53F4d16Ae77Db1c982e75a937B9f60FE63690'
  const gasLimit = 900000000
  const provider = new ethers.providers.JsonRpcProvider({
    url: 'http://localhost:8545',
    timeout: 900000
  })
  const lexer = new ethers.Contract(
    lexerAddress,
    lexerAbi.abi,
    provider
  )
  const astBuilder = new ethers.Contract(
    astAddress,
    astAbi.abi,
    provider
  )
  const interpreter = new ethers.Contract(
    interpreterAddress,
    interpreterAbi.abi,
    provider
  )
  let code = `
  function insertSort() {
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
  }
  `
  let b = Date.now()
  const tokens = await lexer.tokenize(code, {
    gasLimit: gasLimit
  })
  console.log(`tokenize: ${(Date.now() - b)/1000} s`)
  b = Date.now()
  const ast = await astBuilder.build(tokens, {
    gasLimit: gasLimit
  })
  //console.log(ast)
  console.log(`build: ${(Date.now() - b)/1000} s`)
  b = Date.now()
  const result = await interpreter.interpretWithState(ast, makeRunContext(), {
    gasLimit: gasLimit
  })
  console.log(`interpret: ${(Date.now() - b)/1000} s`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
