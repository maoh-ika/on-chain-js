import { ethers, network } from "hardhat";
import snippetJsAbi from '../artifacts/contracts/snippetjs/SnippetJS.sol/SnippetJS'
import lexerAbi from '../artifacts/contracts/lexer/JSLexer.sol/JSLexer'
import { addresses } from './addresses'

async function main() {
  const [owner, admin] = await ethers.getSigners()
  
  const proxyAddress = addresses[network.name]['SnippetJS']['SnippetJSProxy']
  const snippetJs = new ethers.Contract(
    proxyAddress,
    snippetJsAbi.abi,
    ethers.provider
  )
  
  const lexerAddress = addresses[network.name]['lexer']['JSLexer']
  const lexer = new ethers.Contract(
    lexerAddress,
    lexerAbi.abi,
    ethers.provider
  )

  // Solidity ABI encoder
  const coder = ethers.utils.defaultAbiCoder;
  
  const numArg = {
    valueType: 4, // number type
    value: coder.encode(['uint'], [123450000000000000000n]), // 18 digits fixed-point pdecimal. encode into bytes
    numberSign: true, // true: positive, false: negative
    identifierIndex: 0 // fixed to 0
  }
  const strArg = {
    valueType: 1, // string type
    value: coder.encode(['string'], [' ETH']), // encode into bytes
    numberSign: true,
    identifierIndex: 0 // fixed to 0
  }

  const initialState = {
    args: [numArg, strArg],
    identifiers: []
  }

  const code = 'function add(arg1="Default", arg2="Value") { return arg1 + arg2; }'
  const result = await snippetJs.connect(admin).interpretToString(code)
  console.log(result)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
