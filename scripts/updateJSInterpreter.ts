import { ethers, network } from "hardhat";
import { addresses } from './addresses'
import jsInterpreterAbi from '../artifacts/contracts/interpreter/JSInterpreter.sol/JSInterpreter'

async function main() {
  const [owner, admin] = await ethers.getSigners()

  console.log(`Network: ${network.name}`)
  console.log(`Owner Address: ${owner.address}`)
  console.log(`Owner Balance: ${ethers.utils.formatEther(await owner.getBalance())}`)
  console.log(`Admin Address: ${admin.address}`)
  console.log(`Admin Balance: ${ethers.utils.formatEther(await admin.getBalance())}`)
  const gasPrice = await owner.getGasPrice();
  console.log(`Gas price: ${gasPrice}`);

  const jsInterpreterAddress = addresses[network.name]['interpreter']['JSInterpreter']
  const solidityAddress = addresses[network.name]['interpreter']['SolidityVisitor']
  console.log(`JSInterpreter Address: ${jsInterpreterAddress}`)
  console.log(`SolidityVisitor Address: ${solidityAddress}`)
  
  const signer = await ethers.getSigner(owner.address)

  const jsInterpreterContract = new ethers.Contract(
    jsInterpreterAddress,
    jsInterpreterAbi.abi,
    signer
  )
  await jsInterpreterContract.setVisitor(solidityAddress)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
