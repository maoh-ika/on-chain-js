import { ethers } from "hardhat";
import { deploy as deployLexer } from './deployLexer'
import { deploy as deployAst } from './deployAstBuilder'
import { deploy as deployInterpreter } from './deployInterpreter'
import { deploy as deployProxy } from './deployProxy'
import { deploy as deployProxyDebug } from './deployProxyDebug'

async function main() {
  const proxyDebug = await deployProxyDebug() 
  const proxy = await deployProxy() 
  const lexer = await deployLexer()
  const astBuilder = await deployAst()
  const interpreter = await deployInterpreter()
  console.log(`Lexer: ${lexer.address}`);
  console.log(`AstBuilder: ${astBuilder.address}`);
  console.log(`Interpreter: ${interpreter.address}`);
  console.log(`Proxy: ${proxy.address}`);
  console.log(`ProxyDebug: ${proxyDebug.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
