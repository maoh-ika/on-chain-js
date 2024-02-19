// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/lexer/IJSKeywordLexer.sol';
import '../utf8/Utf8.sol';

/**
 * The lexer for reserved keyword tokens.
 */
contract JSKeywordLexer is IJSKeywordLexer {
  struct Keyword {
    // raw expression in the source code
    string expression;
    // internal code
    KeywordCode keywordCode;
  }

  /**
   * Keyword expression to Keyword struct map. To reduce storage cost, the value is a function pointer
   * which returns corresponding struct, instead of struct itself.
   */
  mapping (string => function() internal pure returns (IJSLexer.TokenAttrs memory)) private keywordTokenAttrs;
  
  constructor() {
    keywordTokenAttrs['await'] = _await;
    keywordTokenAttrs['break'] = _break;
    keywordTokenAttrs['case'] = _case;
    keywordTokenAttrs['catch'] = _catch;
    keywordTokenAttrs['class'] = _class;
    keywordTokenAttrs['const'] = _const;
    keywordTokenAttrs['continue'] = _continue;
    keywordTokenAttrs['debugger'] = _debugger;
    keywordTokenAttrs['default'] = _default;
    keywordTokenAttrs['delete'] = _delete;
    keywordTokenAttrs['do'] = _do;
    keywordTokenAttrs['else'] = _else;
    keywordTokenAttrs['enum'] = _enum;
    keywordTokenAttrs['export'] = _export;
    keywordTokenAttrs['extends'] = _extends;
    keywordTokenAttrs['false'] = _false;
    keywordTokenAttrs['finally'] = _finally;
    keywordTokenAttrs['for'] = _for;
    keywordTokenAttrs['function'] = _function;
    keywordTokenAttrs['if'] = _if;
    keywordTokenAttrs['import'] = _import;
    keywordTokenAttrs['in'] = _in;
    keywordTokenAttrs['instanceof'] = _instanceof;
    keywordTokenAttrs['new'] = _new;
    keywordTokenAttrs['null'] = _null;
    keywordTokenAttrs['return'] = _return;
    keywordTokenAttrs['super'] = _super;
    keywordTokenAttrs['switch'] = _switch;
    keywordTokenAttrs['this'] = _this;
    keywordTokenAttrs['throw'] = _throw;
    keywordTokenAttrs['true'] = _true;
    keywordTokenAttrs['try'] = _try;
    keywordTokenAttrs['typeof'] = _typeof;
    keywordTokenAttrs['var'] = _var;
    keywordTokenAttrs['void'] = _void;
    keywordTokenAttrs['while'] = _while;
    keywordTokenAttrs['with'] = _with;
    keywordTokenAttrs['yield'] = _yield;
    keywordTokenAttrs['undefined'] = _undefine;
    keywordTokenAttrs['let'] = _let;
    keywordTokenAttrs['static'] = _static;
    keywordTokenAttrs['implements'] = _implements;
    keywordTokenAttrs['interface'] = _interface;
    keywordTokenAttrs['package'] = _package;
    keywordTokenAttrs['private'] = _private;
    keywordTokenAttrs['protected'] = _protected;
    keywordTokenAttrs['public'] = _public;
  }
  
  /**
   * Get TokenAttribute for specified keyword
   * @param word keyword string.
   * @return TokenAttribute for the word. if not found, returns invalid token
   */
  function getKeywordAttr(string calldata word) external view override returns (IJSLexer.TokenAttrs memory) {
    IJSLexer.TokenAttrs memory invalidAttrs;
    function() internal pure returns(IJSLexer.TokenAttrs memory) invalidFunc;
    function() internal pure returns(IJSLexer.TokenAttrs memory) func = keywordTokenAttrs[word];
    return func != invalidFunc ? func() : invalidAttrs;
  }
  
  /**
   * create attribute for the keyword
   * @param keyword keyword params.
   * @return TokenAttribute for the word.
   */
  function _createKeywordAttrs(Keyword memory keyword) private pure returns (IJSLexer.TokenAttrs memory) {
    uint size = uint(bytes(keyword.expression).length);
    return IJSLexer.TokenAttrs({
      value: abi.encode(keyword.expression), // encode into bytes. use TokenAttrsUtil.decodeKeywordValue for decode
      size: size,
      tokenCode: uint(keyword.keywordCode),
      allowFollowingRegex: false,
      tokenType: IJSLexer.TokenType.keyword
    });
  }
  
  function _await() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'await', keywordCode: KeywordCode._await }));
  }

  function _break() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'break', keywordCode: KeywordCode._break }));
  }

  function _case() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'case', keywordCode: KeywordCode._case }));
  }

  function _catch() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'catch', keywordCode: KeywordCode._catch }));
  }

  function _class() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'class', keywordCode: KeywordCode._class }));
  }

  function _const() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'const', keywordCode: KeywordCode._const }));
  }

  function _continue() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'continue', keywordCode: KeywordCode._continue }));
  }

  function _debugger() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'debugger', keywordCode: KeywordCode._debugger }));
  }

  function _default() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'default', keywordCode: KeywordCode._default }));
  }

  function _delete() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'delete', keywordCode: KeywordCode._delete }));
  }

  function _do() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'do', keywordCode: KeywordCode._do }));
  }

  function _else() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'else', keywordCode: KeywordCode._else }));
  }

  function _enum() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'enum', keywordCode: KeywordCode._enum }));
  }

  function _export() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'export', keywordCode: KeywordCode._export }));
  }

  function _extends() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'extends', keywordCode: KeywordCode._extends }));
  }

  function _false() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'false', keywordCode: KeywordCode._false }));
  }

  function _finally() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'finally', keywordCode: KeywordCode._finally }));
  }

  function _for() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'for', keywordCode: KeywordCode._for }));
  }

  function _function() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'function', keywordCode: KeywordCode._function }));
  }

  function _if() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'if', keywordCode: KeywordCode._if }));
  }

  function _import() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'import', keywordCode: KeywordCode._import }));
  }

  function _in() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'in', keywordCode: KeywordCode._in }));
  }

  function _instanceof() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'instanceof', keywordCode: KeywordCode._instanceof }));
  }

  function _new() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'new', keywordCode: KeywordCode._new }));
  }

  function _null() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'null', keywordCode: KeywordCode._null }));
  }

  function _return() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'return', keywordCode: KeywordCode._return }));
  }

  function _super() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'super', keywordCode: KeywordCode._super }));
  }

  function _switch() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'switch', keywordCode: KeywordCode._switch }));
  }

  function _this() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'this', keywordCode: KeywordCode._this }));
  }

  function _throw() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'throw', keywordCode: KeywordCode._throw }));
  }

  function _true() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'true', keywordCode: KeywordCode._true }));
  }

  function _try() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'try', keywordCode: KeywordCode._try }));
  }

  function _typeof() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'typeof', keywordCode: KeywordCode._typeof }));
  }

  function _var() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'var', keywordCode: KeywordCode._var }));
  }

  function _void() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'void', keywordCode: KeywordCode._void }));
  }

  function _while() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'while', keywordCode: KeywordCode._while }));
  }

  function _with() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'with', keywordCode: KeywordCode._with }));
  }

  function _yield() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'yield', keywordCode: KeywordCode._yield }));
  }

  function _undefine() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'undefined', keywordCode: KeywordCode._undefined}));
  }

  function _let() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'let', keywordCode: KeywordCode._let }));
  }

  function _static() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'static', keywordCode: KeywordCode._static }));
  }

  function _implements() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'implements', keywordCode: KeywordCode._implements }));
  }

  function _interface() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'interface', keywordCode: KeywordCode._interface }));
  }

  function _package() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'package', keywordCode: KeywordCode._package }));
  }

  function _private() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'private', keywordCode: KeywordCode._private }));
  }

  function _protected() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'protected', keywordCode: KeywordCode._protected }));
  }

  function _public() internal pure returns (IJSLexer.TokenAttrs memory) {
    return _createKeywordAttrs(Keyword({ expression: 'public', keywordCode: KeywordCode._public }));
  }
}