import { task } from 'hardhat/config'
import { addresses } from '../scripts/addresses'
import solidityVisitorAbi from '../artifacts/contracts/interpreter/SolidityVisitor.sol/SolidityVisitor'

task('postDeploy', 'post process for deploy contracts')
  .setAction(async (taskArgs, { ethers, network }) => {
    const [owner, admin] = await ethers.getSigners()
    

    console.log(`Network: ${network.name}`)
    console.log(`Owner Address: ${owner.address}`)
    console.log(`Owner Balance: ${ethers.utils.formatEther(await owner.getBalance())}`)
    console.log(`Admin Address: ${admin.address}`)
    console.log(`Admin Balance: ${ethers.utils.formatEther(await admin.getBalance())}`)
    const gasPrice = await owner.getGasPrice();
    console.log(`Gas price: ${gasPrice}`);
  
    const signer = await ethers.getSigner(owner.address)

    if (taskArgs.deployedAddresses['JSInterpreter']) {
      console.log('Run SolidityVisitor.setInterpreter')
      const solidityVisitorAddress = taskArgs.deployedAddresses['SolidityVisitor'] || taskArgs.fixedAddresses['SolidityVisitor']
      const jsInterpreterAddress = taskArgs.deployedAddresses['JSInterpreter']
      console.log(`SolidityVisitor Address: ${solidityVisitorAddress}`)
      console.log(`JSInterpreter Address: ${jsInterpreterAddress}`)
      const contract = new ethers.Contract(
        solidityVisitorAddress,
        solidityVisitorAbi.abi,
        signer
      )
      await contract.setInterpreter(jsInterpreterAddress, { gasLimit: 214320 })
    } else {
      console.log('Skip SolidityVisitor.setInterpreter')
    }
  })