import { ethers, network } from "hardhat";
import { addresses } from './addresses'
import snippetJsAbi from '../artifacts/contracts/snippetjs/SnippetJS.sol/SnippetJS'
import astBuilderAbi from '../artifacts/contracts/ast/AstBuilder.sol/AstBuilder'

async function main() {
  const [owner, admin] = await ethers.getSigners()

  console.log(`Network: ${network.name}`)
  console.log(`Owner Address: ${owner.address}`)
  console.log(`Owner Balance: ${ethers.utils.formatEther(await owner.getBalance())}`)
  console.log(`Admin Address: ${admin.address}`)
  console.log(`Admin Balance: ${ethers.utils.formatEther(await admin.getBalance())}`)
  const gasPrice = await owner.getGasPrice();
  console.log(`Gas price: ${gasPrice}`);

  const astAddress = addresses[network.name]['astBuilder']['AstBuilder']
  console.log(`AstBuilder Address: ${astAddress}`)
  
  const signer = await ethers.getSigner(owner.address)

  const astBuilderContract = new ethers.Contract(
    astAddress,
    astBuilderAbi.abi,
    signer
  )
  const stmBuilder = await astBuilderContract.getStatementBuilder()
  console.log(stmBuilder)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
