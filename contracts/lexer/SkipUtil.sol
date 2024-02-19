// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/lexer/IJSLexer.sol';
import '../utf8/Utf8.sol';
import '../utf8/Utf8Char.sol';

library SkipUtil {
  /**
   * skip spaces
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   */
  function skipSpaces(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) internal pure {
    while (context.currentPos < context.eofPos) {
      IUtf8Char.Utf8Char memory currentChar = Utf8.getNextCharacter(source, context.currentPos);
      if (
        currentChar.code == 0x20 || // space
        currentChar.code == 0xC2A0 || // nonBreakingSpace
        currentChar.code == 0x09 // tab
      ) {
        context.currentPos += currentChar.size;
      } else if (currentChar.code == 0x0d) { // carriageReturn
        IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, context.currentPos + currentChar.size);
        if (nextChar.code == 0x0a) { // lineFeed
          context.currentPos += currentChar.size;
        }
      } else if (
        currentChar.code == 0x0a || // lineFeed
        currentChar.code == 0xE280A8 || // lineSeparator
        currentChar.code == 0xE280A9 // paragraphSeparator
      ) {
        context.currentPos += currentChar.size;
        context.currentLine++;
      } else {
        break;
      }
    }
  }
}