import { ethers } from "hardhat";
import lexerAbi from '../artifacts/contracts/lexer/JSLexer.sol/JSLexer'
import astAbi from '../artifacts/contracts/ast/AstBuilder.sol/AstBuilder'

async function main() {
  const lexerAddress = '0xA3f7BF5b0fa93176c260BBa57ceE85525De2BaF4'
  const astAddress = '0xeE1eb820BeeCED56657bA74fa8D70748D7A6756C'
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
  const code = ` function a() {
  var birthdayMonth = 6;
  var birthdayDay = 30;
  var curMonth = 7;
  var curDay = 0;
  
  var days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var dist = 1;
  return 0;
}`
  let bt = new Date().getTime()
  const tokens = await lexer.tokenize(code, {
    gasLimit: gasLimit
  })
  console.log(`TOKENIZE TIME: ${(new Date().getTime() - bt) / 1000} s`)
  bt = new Date().getTime()
  const ast = await astBuilder.build(tokens, {
    gasLimit: gasLimit
  })
  console.log(`AST TIME: ${(new Date().getTime() - bt) / 1000} s`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
