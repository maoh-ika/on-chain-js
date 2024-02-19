import { ethers } from "hardhat";

import proxyAbi from '../artifacts/contracts/proxy/JSInterpreterProxy.sol/JSInterpreterProxy'

async function main() {
  const [owner, nonOwner] = await ethers.getSigners()
  const provider = ethers.provider
  let totalGas
  
  // ######## Measure ########
  const measureGas = await ethers.getContractFactory("MeasureGas");
  const measureGasContract = await measureGas.deploy()
  
  // ######## Demo ########
  const demo = await ethers.getContractFactory("Demo");
  const demoContract = await demo.deploy()
  
  // Log
  let beforeBalance = await provider.getBalance(owner.address)
  
  const log = await ethers.getContractFactory("Log");
  const logLib = await log.deploy()

  let afterBalance = await provider.getBalance(owner.address)
  let usedGas = beforeBalance.sub(afterBalance)
  const utilsGas = ethers.utils.formatEther(usedGas)
  totalGas = usedGas
  beforeBalance = afterBalance

  // UTF8
  const utf8Char = await ethers.getContractFactory("Utf8Char")
  const utf8CharLib = await utf8Char.deploy()
  
  // ######## Lexers ########

  // number
  const numberLexer = await ethers.getContractFactory("JSNumberLexer", {
    libraries: {
      Utf8Char: utf8CharLib.address
    }
  });
  const numberLexerContract = await numberLexer.deploy()

  // punctuation
  const punctuationLexer = await ethers.getContractFactory("JSPunctuationLexer", {
    libraries: {
      Utf8Char: utf8CharLib.address
    }
  });
  const punctuationLexerContract = await punctuationLexer.deploy()

  // keyword
  const keywordLexer = await ethers.getContractFactory("JSKeywordLexer");
  const keywordLexerontract = await keywordLexer.deploy()
  
  // operator
  const operatorLexer = await ethers.getContractFactory("JSOperatorLexer", {
    libraries: {
      Utf8Char: utf8CharLib.address
    }
  });
  const operatorLexerContract = await operatorLexer.deploy()

  // identifier
  const identifierLexer = await ethers.getContractFactory("JSIdentifierLexer", {
    libraries: {
      Utf8Char: utf8CharLib.address
    }
  });
  const identifierLexerContract = await identifierLexer.deploy(numberLexerContract.address)
  
  // regex
  const regexLexer = await ethers.getContractFactory("JSRegexLexer", {
    libraries: {
      Utf8Char: utf8CharLib.address
    }
  });
  const regexLexerontract = await regexLexer.deploy(identifierLexerContract.address);
  
  // string
  const stringLexer = await ethers.getContractFactory("JSStringLexer", {
    libraries: {
      Utf8Char: utf8CharLib.address
    }
  });
  const stringLexerContract = await stringLexer.deploy(numberLexerContract.address, identifierLexerContract.address)

  // lexer main
  const lexer = await ethers.getContractFactory("JSLexer", {
    libraries: {
//      Log: logLib.address,
      Utf8Char: utf8CharLib.address
    }
  })
  const lexerContract = await lexer.deploy(
    stringLexerContract.address,
    numberLexerContract.address,
    punctuationLexerContract.address,
    keywordLexerontract.address,
    operatorLexerContract.address,
    regexLexerontract.address,
    identifierLexerContract.address
  )
  afterBalance = await provider.getBalance(owner.address)
  usedGas = beforeBalance.sub(afterBalance)
  const lexerGas = ethers.utils.formatEther(usedGas)
  totalGas = totalGas.add(usedGas)
  beforeBalance = afterBalance
  
  // ######## Ast Builder ########

  const expressionBuilder = await ethers.getContractFactory("ExpressionBuilder", {
    libraries: {
//     Log: logLib.address,
    }
})
  const expressionBuilderContract = await expressionBuilder.deploy()
  
  const statementBuilder = await ethers.getContractFactory("StatementBuilder", {
    libraries: {
//     Log: logLib.address,
    }
  })
  const statementBuilderContract = await statementBuilder.deploy(expressionBuilderContract.address)
  
  // builder main
  const builder = await ethers.getContractFactory("AstBuilder", {
    libraries: {
//      Log: logLib.address,
    }
  })
  const astBuilderContract = await builder.deploy(statementBuilderContract.address);
  
  afterBalance = await provider.getBalance(owner.address)
  usedGas = beforeBalance.sub(afterBalance)
  const astGas = ethers.utils.formatEther(usedGas)
  totalGas = totalGas.add(usedGas)
  beforeBalance = afterBalance
  
  // ######## Interpreter ########
  const stringUtil = await ethers.getContractFactory("StringUtil");
  const stringUtilLib = await stringUtil.deploy()

  const jsValueUtil = await ethers.getContractFactory("JSValueUtil", {
    libraries: {
      StringUtil: stringUtilLib.address
    }
  });
  const jsValueUtilLib = await jsValueUtil.deploy();
  
  // op
  const jsValueOp = await ethers.getContractFactory("JSValueOp", {
    libraries: {
      JSValueUtil: jsValueUtilLib.address
    }
  });
  const jsValueOpLib = await jsValueOp.deploy();
  // compare
  const jsValueCompare = await ethers.getContractFactory("JSValueCompare")
  const jsValueCompareLib = await jsValueCompare.deploy();
  // bit
  const jsValueBit = await ethers.getContractFactory("JSValueBit")
  const jsValueBitLib = await jsValueBit.deploy();
  // literal
  const jsLiteral = await ethers.getContractFactory("JSLiteralUtil");
  const jsLiteralLib = await jsLiteral.deploy();

  // call
  const contractCall = await ethers.getContractFactory("ContractCall")
  const contractCallContract = await contractCall.deploy();
  
  const solidityVisitor = await ethers.getContractFactory("SolidityVisitor", {
    libraries: {
//      Log: logLib.address,
      JSValueUtil: jsValueUtilLib.address,
      JSValueOp: jsValueOpLib.address,
      JSValueCompare: jsValueCompareLib.address,
      JSValueBit: jsValueBitLib.address,
      JSLiteralUtil: jsLiteralLib.address
    }
  });
  const codeTokenAddress = '0x1613beB3B2C4f22Ee086B2b38C1476A3cE7f78E8'
  const solidityVisitorContract = await solidityVisitor.deploy(codeTokenAddress, contractCallContract.address)

  const interpreter = await ethers.getContractFactory("JSInterpreter", {
    libraries: {
      Log: logLib.address,
      JSValueUtil: jsValueUtilLib.address
    }
  })
  const interpreterContract = await interpreter.deploy(solidityVisitorContract.address);
  
  afterBalance = await provider.getBalance(owner.address)
  usedGas = beforeBalance.sub(afterBalance)
  const interpreterGas = ethers.utils.formatEther(usedGas)
  totalGas = totalGas.add(usedGas)
  beforeBalance = afterBalance

  // ######## SnippetJS ########
 
  const snippetJs = await ethers.getContractFactory("SnippetJS")
  const spinContract = await snippetJs.deploy();
  await spinContract.deployed()
  
  const spinProxy = await ethers.getContractFactory("SnippetJSProxy")
  const spinProxyContract = await spinProxy.deploy(spinContract.address, owner.address, ethers.utils.toUtf8Bytes(""))
  await spinProxyContract.deployed()
  // initialize SnippetJS via proxy
  await spinContract.attach(spinProxyContract.address).connect(nonOwner).initialize(
    lexerContract.address,
    astBuilderContract.address,
    interpreterContract.address
  )
  
  afterBalance = await provider.getBalance(owner.address)
  usedGas = beforeBalance.sub(afterBalance)
  const spinGas = ethers.utils.formatEther(usedGas)
  totalGas = totalGas.add(usedGas)
  beforeBalance = afterBalance
  
  console.log(['[Addresses]'])
  console.log(`  Log: ${logLib.address}`)
  console.log(`  LexerLogic: ${lexerContract.address}`)
  console.log(`  AstBuilder: ${astBuilderContract.address}`)
  console.log(`  Interpreter: ${interpreterContract.address}`)
  console.log(`  SnippetJSLogic: ${spinContract.address}`)
  console.log(`  SnippetJSProxy: ${spinProxyContract.address}`)
  console.log(`  Measure: ${measureGasContract.address}`)
  console.log(`  Demo: ${demoContract.address}`)
  console.log(['[Gas Used]'])
  console.log(`  Utils: ${utilsGas} ETH`)
  console.log(`  Lexer: ${lexerGas} ETH`)
  console.log(`  Ast: ${astGas} ETH`)
  console.log(`  Interpreter: ${interpreterGas} ETH`)
  console.log(`  Snippet: ${spinGas} ETH`)
  console.log(`  Total: ${ethers.utils.formatEther(totalGas)} ETH`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
