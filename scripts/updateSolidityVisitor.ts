import { ethers, network } from "hardhat";
import { addresses } from './addresses'
import solidityVisitorAbi from '../artifacts/contracts/interpreter/SolidityVisitor.sol/SolidityVisitor'

async function main() {
  const [owner, admin] = await ethers.getSigners()

  console.log(`Network: ${network.name}`)
  console.log(`Owner Address: ${owner.address}`)
  console.log(`Owner Balance: ${ethers.utils.formatEther(await owner.getBalance())}`)
  console.log(`Admin Address: ${admin.address}`)
  console.log(`Admin Balance: ${ethers.utils.formatEther(await admin.getBalance())}`)
  const gasPrice = await owner.getGasPrice();
  console.log(`Gas price: ${gasPrice}`);

  const globalFunctionAddress = addresses[network.name]['interpreter']['GlobalFunction']
  const solidityVisitorAddress = addresses[network.name]['interpreter']['SolidityVisitor']
  console.log(`GlobalFunction Address: ${globalFunctionAddress}`)
  console.log(`SolidityVisitor Address: ${solidityVisitorAddress}`)
  
  const signer = await ethers.getSigner(owner.address)

  const contract = new ethers.Contract(
    solidityVisitorAddress,
    solidityVisitorAbi.abi,
    signer
  )
  await contract.setGlobalFunction(globalFunctionAddress, { gasLimit: 214320 })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
