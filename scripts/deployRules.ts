import { utils } from 'ethers' 

export type AddressSrc = 'fixed' | 'dynamic' | 'dummy' | 'external'

export interface LibRule {
  name: string
  addressSrc: AddressSrc
}

export interface ProxyRule {
  contract: ContractRule 
  addressSrc: AddressSrc
  init: ArgRule[]
}

export interface ArgRule {
  address?: LibRule
  value?: any
}

export interface ContractRule {
  name: string
  libs?: LibRule[]
  args?: ArgRule[]
  proxy?: ProxyRule
  addressSrc: AddressSrc
}

export interface ModuleRule {
  name: string
  contracts: ContractRule[]
}

type DeployRules = {[key:string]: ModuleRule[]}

export const deployRules: DeployRules = {
  localhost: [
    {
      name: 'utils',
      contracts: [
        { name: 'Log', addressSrc: 'fixed' },
        { name: 'MeasureGas', addressSrc: 'fixed' },
        { name: 'Demo', addressSrc: 'fixed' }
      ]
    },
    {
      name: 'lexer',
      contracts: [
        { name: 'Utf8Char', addressSrc: 'fixed' },
        {
          name: 'JSNumberLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          addressSrc: 'fixed'
        },
        {
          name: 'JSPunctuationLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          addressSrc: 'fixed'
        },
        { name: 'JSKeywordLexer', addressSrc: 'fixed' },
        {
          name: 'JSOperatorLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          addressSrc: 'fixed'
        },
        {
          name: 'JSIdentifierLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [{ address:{ name: 'JSNumberLexer', addressSrc: 'fixed' }}],
          addressSrc: 'fixed'
        },
        {
          name: 'JSRegexLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [{ address:{ name: 'JSIdentifierLexer', addressSrc: 'fixed' }}],
          addressSrc: 'fixed'
        },
        {
          name: 'JSStringLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [
            { address: { name: 'JSNumberLexer', addressSrc: 'fixed' }},
            { address: { name: 'JSIdentifierLexer', addressSrc: 'fixed' }}
          ],
          addressSrc: 'fixed'
        },
        {
          name: 'JSLexer',
          libs: [
           // { name: 'Log', addressSrc: 'fixed' },
            { name: 'Utf8Char', addressSrc: 'fixed' }
          ],
          args: [
            { address:{ name: 'JSStringLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSNumberLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSPunctuationLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSKeywordLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSOperatorLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSRegexLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSIdentifierLexer', addressSrc: 'fixed'} }
          ],
          addressSrc: 'fixed'
        }
      ]
    },
    {
      name: 'astBuilder',
      contracts: [
        { name: 'ExpressionBuilder', addressSrc: 'fixed' },
        { name: 'StatementBuilder', args: [{ address: { name: 'ExpressionBuilder', addressSrc: 'fixed' }}], addressSrc: 'fixed' },
        { name: 'AstBuilder',
          libs: [
          // { name: 'Log', addressSrc: 'fixed' },
          ],
          args: [{ address: { name: 'StatementBuilder', addressSrc: 'fixed' }}],
          addressSrc: 'fixed'
        },
      ]
    },
    {
      name: 'interpreter',
      contracts: [
        { name: 'StringUtil', addressSrc: 'fixed' },
        { name: 'JSValueUtil',libs: [
            { name: 'StringUtil', addressSrc: 'fixed' },
          //  { name: 'Log', addressSrc: 'fixed' },
          ],
          addressSrc: 'fixed'
        },
        { name: 'JSLiteralUtil', addressSrc: 'fixed' },
        { name: 'JSValueOp', libs: [
            { name: 'JSValueUtil', addressSrc: 'fixed' }
          ],
          addressSrc: 'fixed'
        },
        { name: 'GlobalFunction', addressSrc: 'fixed',
          args: [
            { address: { name: 'ExeTokenProxy', addressSrc: 'external' }}
          ],
          libs: [
            //{ name: 'Log', addressSrc: 'fixed' },
          ],
        },
        { name: 'SolidityVisitor',
          libs: [
            //{ name: 'Log', addressSrc: 'fixed' },
            { name: 'JSValueUtil', addressSrc: 'fixed' },
            { name: 'JSValueOp', addressSrc: 'fixed' },
            { name: 'JSLiteralUtil', addressSrc: 'fixed' }
          ],
          args: [
            { address: { name: 'GlobalFunction', addressSrc: 'fixed' }},
            { address: { name: 'JSInterpreter', addressSrc: 'dummy' }}
          ],
          addressSrc: 'fixed'
        },
        { name: 'JSInterpreter',
          libs: [
            // { name: 'Log', addressSrc: 'fixed' },
            { name: 'StringUtil', addressSrc: 'fixed' }
          ],
          args: [{ address: { name: 'SolidityVisitor', addressSrc: 'fixed' }}],
          addressSrc: 'fixed'
        }
      ]
    },
    {
      name: 'SnippetJS',
      contracts: [
        { name: 'SnippetJS',
          proxy: {
            contract: {
              name: 'SnippetJSProxy',
              args: [
                { address: { name: 'SnippetJS', addressSrc: 'fixed' }},
                { address: { name: 'owner', addressSrc: 'fixed' }},
                { value: utils.toUtf8Bytes('') },
              ],
              addressSrc: 'fixed'
            },
            addressSrc: 'fixed',
            init: [
              { address: { name: 'JSLexer', addressSrc: 'fixed' }},
              { address: { name: 'AstBuilder', addressSrc: 'fixed' }},
              { address: { name: 'JSInterpreter', addressSrc: 'fixed' }},
            ]
          },
          addressSrc: 'fixed'
        }
      ]
    }
  ],
  goerli: [
    {
      name: 'utils',
      contracts: [
        { name: 'MeasureGas', addressSrc: 'fixed' },
        { name: 'Demo', addressSrc: 'fixed' }
      ]
    },
    {
      name: 'lexer',
      contracts: [
        { name: 'Utf8Char', addressSrc: 'fixed' },
        {
          name: 'JSNumberLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          addressSrc: 'fixed'
        },
        {
          name: 'JSPunctuationLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          addressSrc: 'fixed'
        },
        { name: 'JSKeywordLexer', addressSrc: 'fixed' },
        {
          name: 'JSOperatorLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          addressSrc: 'fixed'
        },
        {
          name: 'JSIdentifierLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [{ address:{ name: 'JSNumberLexer', addressSrc: 'fixed' }}],
          addressSrc: 'fixed'
        },
        {
          name: 'JSRegexLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [{ address:{ name: 'JSIdentifierLexer', addressSrc: 'fixed' }}],
          addressSrc: 'fixed'
        },
        {
          name: 'JSStringLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [
            { address: { name: 'JSNumberLexer', addressSrc: 'fixed' }},
            { address: { name: 'JSIdentifierLexer', addressSrc: 'fixed' }}
          ],
          addressSrc: 'fixed'
        },
        {
          name: 'JSLexer',
          libs: [{ name: 'Utf8Char', addressSrc: 'fixed' }],
          args: [
            { address:{ name: 'JSStringLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSNumberLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSPunctuationLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSKeywordLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSOperatorLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSRegexLexer', addressSrc: 'fixed' }},
            { address:{ name: 'JSIdentifierLexer', addressSrc: 'fixed'} }
          ],
          addressSrc: 'fixed'
        }
      ]
    },
    {
      name: 'astBuilder',
      contracts: [
        { name: 'ExpressionBuilder', addressSrc: 'fixed' },
        { name: 'StatementBuilder', args: [{ address: { name: 'ExpressionBuilder', addressSrc: 'fixed' }}], addressSrc: 'fixed' },
        { name: 'AstBuilder', args: [{ address: { name: 'StatementBuilder', addressSrc: 'fixed' }}], addressSrc: 'fixed' },
      ]
    },
    {
      name: 'interpreter',
      contracts: [
        { name: 'StringUtil', addressSrc: 'fixed' },
        { name: 'JSValueUtil',libs: [
            { name: 'StringUtil', addressSrc: 'fixed' },
          ],
          addressSrc: 'dynamic'
        },
        { name: 'JSLiteralUtil', addressSrc: 'fixed' },
        { name: 'JSValueOp', libs: [
            { name: 'JSValueUtil', addressSrc: 'dynamic' }
          ],
          addressSrc: 'dynamic'
        },
        { name: 'GlobalFunction', addressSrc: 'dynamic',
          args: [
            { address: { name: 'ExeTokenProxy', addressSrc: 'external' }}
          ],
          libs: [
          ],
        },
        { name: 'SolidityVisitor',
          libs: [
            { name: 'JSValueUtil', addressSrc: 'dynamic' },
            { name: 'JSValueOp', addressSrc: 'dynamic' },
            { name: 'JSLiteralUtil', addressSrc: 'fixed' }
          ],
          args: [
            { address: { name: 'GlobalFunction', addressSrc: 'dynamic' }}
          ],
          addressSrc: 'dynamic'
        },
        { name: 'JSInterpreter',
          libs: [
            { name: 'StringUtil', addressSrc: 'fixed' }
          ],
          args: [{ address: { name: 'SolidityVisitor', addressSrc: 'dynamic' }}],
          addressSrc: 'dynamic'
        }
      ]
    },
    {
      name: 'SnippetJS',
      contracts: [
        { name: 'SnippetJS',
          addressSrc: 'dynamic',
          proxy: {
            contract: {
              name: 'SnippetJSProxy',
              addressSrc: 'fixed',
              args: [
                { address: { name: 'SnippetJS', addressSrc: 'dynamic' }},
                { address: { name: 'owner', addressSrc: 'fixed' }},
                { value: utils.toUtf8Bytes('') },
              ],
            },
            addressSrc: 'fixed',
            init: [
              { address: { name: 'JSLexer', addressSrc: 'fixed' }},
              { address: { name: 'AstBuilder', addressSrc: 'fixed' }},
              { address: { name: 'JSInterpreter', addressSrc: 'dynamic' }},
            ]
          },
        }
      ]
    }
  ]
}