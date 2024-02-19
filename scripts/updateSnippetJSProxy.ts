import { ethers, network } from "hardhat";
import { addresses } from './addresses'
import snippetJsAbi from '../artifacts/contracts/snippetjs/SnippetJS.sol/SnippetJS'
import snippetJsProxyAbi from '../artifacts/contracts/snippetjs/SnippetJSProxy.sol/SnippetJSProxy'

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
  console.log(`SnippetJSProxy Address: ${snippetProxyAddress}`)
  console.log(`SnippetJS Address: ${snippetJSAddress}`)
  
  const signer = await ethers.getSigner(owner.address)

  const snippetContract = new ethers.Contract(
    snippetProxyAddress,
    snippetJsProxyAbi.abi,
    signer
  )
  await snippetContract.upgradeTo(snippetJSAddress, { gasLimit: 214320 })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
