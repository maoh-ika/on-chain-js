import { ethers, network } from "hardhat";
import { addresses } from './addresses'
import globalFunctionAbi from '../artifacts/contracts/interpreter/GlobalFunction.sol/GlobalFunction'

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
  const exeTokenAddress = addresses[network.name]['lib']['ExeTokenProxy']
  console.log(`GlobalFunction Address: ${globalFunctionAddress}`)
  console.log(`ExeTokenProxy Address: ${exeTokenAddress}`)
  
  const signer = await ethers.getSigner(owner.address)

  const contract = new ethers.Contract(
    globalFunctionAddress,
    globalFunctionAbi.abi,
    signer
  )
  await contract.setexeToken(exeTokenAddress, { gasLimit: 214320 })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
