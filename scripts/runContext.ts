import { ethers } from 'hardhat';

export function makeEmptyContext(): any {
  return {
    args: [],
    identifiers: []
  }
}

export function makeRunContext(useArgs: boolean=false): any {
  const coder = ethers.utils.defaultAbiCoder;
  const objType = ethers.utils.ParamType.from({
    "components": [
      {
        "components": [
          {
            "internalType": "bytes",
            "name": "value",
            "type": "bytes"
          },
          {
            "internalType": "string",
            "name": "key",
            "type": "string"
          },
          {
            "internalType": "bytes32",
            "name": "keyHash",
            "type": "bytes32"
          },
          {
            "internalType": "bool",
            "name": "numberSign",
            "type": "bool"
          },
          {
            "internalType": "enum IJSInterpreter.JSValueType",
            "name": "valueType",
            "type": "uint8"
          }
        ],
        "internalType": "struct IJSInterpreter.JSObjectProperty[]",
        "name": "properties",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256",
        "name": "rootPropertyIndex",
        "type": "uint256"
      }
    ],
    "internalType": "struct IJSInterpreter.JSObject",
    "name": "obj",
    "type": "tuple"
  })

  let args: any[] = []
  if (useArgs) {
    args = [
      {
        valueType: 1,
        identifierIndex: 0,
        value: coder.encode(['string'], ["argValue"]),
        numberSign: false,
        arrayValue: {
          elements: [],
          rootElementIndex: 0,
          size: 0
        },
        objectValue: {
          properties: [],
          rootPropertyIndex: 0,
          size: 0
        }
      }
    ]
  }
  return {
    startNodeIndex: 0,
    args: args,
    identifiers: [
      {
        name: "ethreumBlock",
        value: {
          valueType: 7,
          identifierIndex: 0,
          numberSign: false,
          value: coder.encode([objType],[{
            properties: [
              {
                valueType: 7,
                value: coder.encode(['uint[]'], [[1]]),
                key: "",
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("")),
                numberSign: false,
              },
              {
                valueType: 4,
                key: 'blockNumber',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("blockNumber")),
                value: coder.encode(['uint'], [222]),
                stringValue: "",
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'year',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("year")),
                value: coder.encode(['uint'], [2022]),
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'month',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("month")),
                value: coder.encode(['uint'], [6]),
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'day',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("day")),
                value: coder.encode(['uint'], [12]),
                numberSign: true,
              }
            ],
            rootPropertyIndex: 0,
            size: 2
          }])
        }
      },
      {
        name: "tokenAttributes",
        value: {
          valueType: 7,
          identifierIndex: 0,
          numberSign: false,
          value: coder.encode([objType],[{
            properties: [
              {
                valueType: 7,
                value: coder.encode(['uint[]'], [[1,2,3,4,5,6,7,8,9,10]]),
                key: "",
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("")),
                numberSign: false,
              },
              {
                valueType: 4,
                key: 'timestamp',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("timestamp")),
                value: coder.encode(['uint'], [222]),
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'year',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("year")),
                value: coder.encode(['uint'], [1]),
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'month',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("month")),
                value: coder.encode(['uint'], [2]),
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'day',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("day")),
                value: coder.encode(['uint'], [3]),
                numberSign: true,
              },
              {
                valueType: 4,
                key: 'blockNumber',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("blockNumber")),
                value: coder.encode(['uint'], [4]),
                numberSign: true,
              },
              {
                valueType: 1,
                key: 'backgroundContent',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("backgroundContent")),
                value: coder.encode(['string'], ['']),
                numberSign: true,
              },
              {
                valueType: 1,
                key: 'backgroundColor',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("backgroundColor")),
                value: coder.encode(['string'], ['#000000']),
                numberSign: true,
              },
              {
                valueType: 1,
                key: 'backgroundOpacity',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("backgroundOpacity")),
                value: coder.encode(['string'], ['1.0']),
                numberSign: true,
              },
              {
                valueType: 1,
                key: 'frontContent',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("frontContent")),
                value: coder.encode(['string'], ['result']),
                numberSign: true,
              },
              {
                valueType: 1,
                key: 'frontColor',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("frontColor")),
                value: coder.encode(['string'], ['#000000']),
                numberSign: true,
              },
              {
                valueType: 1,
                key: 'frontOpacity',
                keyHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("frontOpacity")),
                value: coder.encode(['string'], ['1.0']),
                numberSign: true,
              }
            ],
            rootPropertyIndex: 0,
            size: 11
          }])
        }
      }
    ]
  }
}