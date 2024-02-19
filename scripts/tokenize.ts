import { ethers } from "hardhat";
import lexerAbi from '../artifacts/contracts/lexer/JSLexer.sol/JSLexer'

const toTokenType = (val: number): string => {
  switch(val) {
    case 0: return 'keyword'; break
    case 1: return 'punctuation'; break
    case 2: return 'operator'; break
    case 3: return 'identifer'; break
    case 4: return 'number'; break
    case 5: return 'bigInt'; break
    case 6: return 'str'; break
    case 7: return 'regex'; break
    default: return 'unknown'
  }
}

async function main() {
  const lexerAddress = '0x01cf58e264d7578D4C67022c58A24CbC4C4a304E'
  const gasLimit = 100000000
  const provider = new ethers.providers.JsonRpcProvider({
    url: 'http://localhost:8545',
    timeout: 300000
  })
  const lexer = new ethers.Contract(
    lexerAddress,
    lexerAbi.abi,
    provider
  )
  const code = `
    function a() {
  var birthdayMonth = 6;
  var birthdayDay = 30;
  var curMonth = 7;
  var curDay = 0;
  
  var days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var dist = 1;
  for (var m = birthdayMonth; m >= 0; --m) {
    var start = birthdayDay - 1;
    if (m != birthdayMonth) {
      start = days[m] - 1;
    } 
    for (var d = start; d >= 0; --d) {
      if (m == curMonth && d == curDay) {
        return dist;
      }
      ++dist;
    }
  }
  dist = 1;
  for (var m = birthdayMonth; m < 11; ++m) {
    var start2 = birthdayDay + 1;
    if (m != birthdayMonth) {
      start2 = 0;
    }
    for (var d = start2; d < days[m]; ++d) {
      if (m == curMonth && d == curDay) {
        return 365 - dist;
      }
      ++dist;
    }
  }
  return 0;
}`

  const bt = new Date().getTime()
  const res = await lexer.tokenize(code, {
    gasLimit: gasLimit 
  })
  console.log(`TIME: ${(new Date().getTime() - bt) / 1000} s`)
  const tokens = res.map((r: any) => {
    return {
      expression: r.attrs.expression,
      value: r.attrs.value,
      sign: r.attrs.sign,
      tokenType: toTokenType(r.attrs.tokenType),
    }
  })
  //console.log(tokens)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
