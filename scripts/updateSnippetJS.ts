import { ethers, network } from "hardhat";
import { addresses } from './addresses'
import snippetJsAbi from '../artifacts/contracts/snippetjs/SnippetJS.sol/SnippetJS'

async function main() {
  const [owner, admin] = await ethers.getSigners()

  console.log(`Network: ${network.name}`)
  console.log(`Owner Address: ${owner.address}`)
  console.log(`Owner Balance: ${ethers.utils.formatEther(await owner.getBalance())}`)
  console.log(`Admin Address: ${admin.address}`)
  console.log(`Admin Balance: ${ethers.utils.formatEther(await admin.getBalance())}`)
  const gasPrice = await owner.getGasPrice();
  console.log(`Gas price: ${gasPrice}`);

  const snippetProxyAddress = addresses[network.name]['SnippetJS']['SnippetJSProxy']
  const snippetJSAddress = addresses[network.name]['SnippetJS']['SnippetJS']
  const jsInterpreterAddress = addresses[network.name]['interpreter']['JSInterpreter']
  const lexerAddress = addresses[network.name]['lexer']['JSLexer']
  const astAddress = addresses[network.name]['astBuilder']['AstBuilder']
  console.log(`SnippetJSProxy Address: ${snippetProxyAddress}`)
  console.log(`SnippetJS Address: ${snippetJSAddress}`)
  console.log(`JSInterpreter Address: ${jsInterpreterAddress}`)
  console.log(`JSLexer Address: ${lexerAddress}`)
  console.log(`AstBuilder Address: ${astAddress}`)
  
  const signer = await ethers.getSigner(admin.address)

  const snippetContract = new ethers.Contract(
    snippetProxyAddress,
    snippetJsAbi.abi,
    signer
  )
  await snippetContract.setLexer(lexerAddress,  { gasLimit: 214320 })
  await snippetContract.setAstBuilder(astAddress,  { gasLimit: 214320 })
  await snippetContract.setInterpreter(jsInterpreterAddress,  { gasLimit: 214320 })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
