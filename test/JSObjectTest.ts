import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect, assert } from 'chai';
import { ethers } from 'hardhat';
import measureAbi from '../artifacts/contracts/utils/MeasureGas.sol/MeasureGas'
import { addresses } from '../scripts/addresses'
import { makeRunContext } from '../scripts/runContext'

describe('JSObjectTest', function () {
  const gasLimit = 100000000
  const proxyAddress = addresses['localhost']['SnippetJS']['SnippetJSProxy']
  const measuerAddress = addresses['localhost']['utils']['MeasureGas']

  async function deployFixture() {
    const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545/')
    return new ethers.Contract(
      measuerAddress,
      measureAbi.abi,
      provider
    )
  }

  async function interpret(code: string, useArgs: boolean=false, initState: any=undefined) {
    const state = initState === undefined ? makeRunContext(useArgs) : initState
    const measure = await loadFixture(deployFixture);
    const res = await measure.measureSnippet(proxyAddress, code, state, { gasLimit: gasLimit })
    return { result: res[0], gas: +res[1] }
  }
  
  let gasTotal = 0

  function makeTest(name: string, code: string, expected: any, only: boolean=false) {
    const testFunc = only ? it.only : it
    testFunc(`${name}`, async function () {
      const { result, gas } = await interpret(code)
      console.log(`${name}: ${gas}`)
      gasTotal += gas;
      expect(result).to.equal(expected);
    })
  }
  
  function makeTestError(name: string, code: string, errMsg: string, only: boolean=false) {
    const testFunc = only ? it.only : it
    testFunc(`${name}`, async function () {
      try {
        const { result, gas } = await interpret(code)
        assert.fail()
      } catch (err) {
        assert.throws(function() { throw err }, Error, errMsg)
      }
    })
  }

  before(async function() {
    await loadFixture(deployFixture);
  });

  after(async function() {
    console.log(`GAS TOTAL: ${gasTotal}`)
  })

  describe('declare', function () {
    makeTest('declare_empty', `function func() { var arr = {}; return arr; }`, '{}')
    makeTest('declare_integer', `function func() { var arr = {int: 1}; return arr; }`, '{"int":1}')
    makeTest('declare_integer_dup', `function func() { var arr = {int: 1, int:99}; return arr; }`, '{"int":99}')
    makeTest('declare_decimal', `function func() { var arr = {flt:1.2}; return arr; }`, '{"flt":1.2}')
    makeTest('declare_exponent', `function func() { var arr = { exp : 3e2 }; return arr; }`, '{"exp":300}')
    makeTest('declare_hex', `function func() { var arr = {hex:0xff}; return arr; }`, '{"hex":255}')
    makeTest('declare_binary', `function func() { var arr = {bin :0b11}; return arr; }`, '{"bin":3}')
    makeTest('declare_octal', `function func() { var arr = {oct:0o11}; return arr; }`, '{"oct":9}')
    makeTest('declare_string', `function func() { var arr = {str:'abc'}; return arr; }`, `{"str":"abc"}`)
    makeTest('declare_bool', `function func() { var arr = {bl:true}; return arr; }`, `{"bl":true}`)
    makeTest('declare_object', `function func() { var arr = {obj: {a:1, b: 'a'}}; return arr; }`, `{"obj":{"a":1,"b":"a"}}`)
    makeTest('declare_array', `function func() { var arr = {arr: [1, 'a']}; return arr; }`, `{"arr":[1,"a"]}`)
    makeTest('declare_integer_multi', `function func() { var arr = {int1: 1,int2:2,int3:3}; return arr; }`, '{"int1":1,"int2":2,"int3":3}')
    makeTest('declare_decimal_multi', `function func() { var arr = {flt1: 1.2,flt2: 0.123,flt3: 12.040}; return arr; }`, '{"flt1":1.2,"flt2":0.123,"flt3":12.04}')
    makeTest('declare_exponent_multi', `function func() { var arr = {exp1:3e2,exp2:0e1,exp3:12e-3}; return arr; }`, '{"exp1":300,"exp2":0,"exp3":0.012}')
    makeTest('declare_hex_multi', `function func() { var arr = {hex1:0xff,hex2:0x12,hex3:0x0b}; return arr; }`, '{"hex1":255,"hex2":18,"hex3":11}')
    makeTest('declare_binary_multi', `function func() { var arr = {bin1:0b11,bin2:0b00,bin3:0b10}; return arr; }`, '{"bin1":3,"bin2":0,"bin3":2}')
    makeTest('declare_octal_multi', `function func() { var arr = {oct1:0o11,oct2:0o70,oct3:0o77}; return arr; }`, '{"oct1":9,"oct2":56,"oct3":63}')
    makeTest('declare_string_multi', `function func() { var arr = {str1:'abc',str2:'',str3:'defg'}; return arr; }`, `{"str1":"abc","str2":"","str3":"defg"}`)
    makeTest('declare_bool_multi', `function func() { var arr = {bl1:true,bl2:true,bl3:false}; return arr; }`, `{"bl1":true,"bl2":true,"bl3":false}`)
    makeTest('declare_all_multi', `function func() { var arr = {int:100, flt:2.3, exp:2e-1, hex:0xe91,bin:0b00,oct:0o071,str:' AFGg ', bl:true}; return arr; }`, `{"int":100,"flt":2.3,"exp":0.2,"hex":3729,"bin":0,"oct":57,"str":" AFGg ","bl":true}`)
    makeTest('declare_nest', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr; }`, `{"obj1":{"int":1,"flt":23.4},"obj2":{"str":"aa","str2":"bb"}}`)
    makeTest('declare_nest_multi', `function func() { var arr = {obj1:{int1:1,int2:23,int3:4},  obj2:{str1:"1", str2:"a", str3:"b"}, obj3:{obj4:{}, obj5:{int1:99}}}; return arr; }`, `{"obj1":{"int1":1,"int2":23,"int3":4},"obj2":{"str1":"1","str2":"a","str3":"b"},"obj3":{"obj4":{},"obj5":{"int1":99}}}`)
    makeTest('declare_object_in-array-object', `function func() { var c = {a: [{b:3}, 2]}; return c; }`, `{"a":[{"b":3},2]}`)
    makeTest('declare_object_in-array-object2', `function func() { var c = {a: [{b:3, d:[1]}, 2]}; return c; }`, `{"a":[{"b":3,"d":[1]},2]}`)
    makeTest('declare_object-array-nest', `function func() { var c = {a:[{b:[1]}]}; return c; }`, `{"a":[{"b":[1]}]}`)
    makeTest('declare_ref_integer', `function func() { var v0 = 0; var v1 = 1 return {num:v0,num2:v1}; }`, '{"num":0,"num2":1}')
    makeTest('declare_ref_decimal', `function func() { var v0 = 0.0; var v1 = 1.2 return {num:v0,num2:v1}; }`, '{"num":0,"num2":1.2}')
    makeTest('declare_ref_bool', `function func() { var v0 = true; var v1 = false; return {bl:v0,bl2:v1}; }`, '{"bl":true,"bl2":false}')
    makeTest('declare_ref_string', `function func() { var v0 = ''; var v1 = 'abc'; return {str:v0,str2:v1}; }`, '{"str":"","str2":"abc"}')
    makeTest('declare_ref_array', `function func() { var v0 = [1,2]; var v1 = 3; return {arr:v0,num:v1}; }`, '{"arr":[1,2],"num":3}')
    makeTest('declare_ref_object', `function func() { var v0 = { num:1, num2: 2}; var v1 = 3; return {obj:v0,num:v1}; }`, '{"obj":{"num":1,"num2":2},"num":3}')
    makeTest('declare_ref_nest', `function func() { var v0 = [1,2]; var v1 = 1; var v2 = v0; return {arr:v2,num:v1}; }`, '{"arr":[1,2],"num":1}')
  })
  
  describe('access', function () {
    makeTest('access_computed', `function func() { var arr = {int: 1}; return arr["int"]; }`, '1')
    makeTest('access_computed2', `function func() { var arr = {int: 1}; return arr['int']; }`, '1')
    makeTest('access_computed3', `function func() { var arr = {int: 1, str:"int"}; return arr['str']; }`, 'int')
    makeTest('access_property', `function func() { var arr = {int: 1}; return arr.int; }`, '1')
    makeTest('access_property2', `function func() { var arr = {int: 1, str:"int"}; return arr.str; }`, 'int')
    makeTest('access_integer_dup', `function func() { var arr = {int: 1, int:99}; return arr.int; }`, '99')
    makeTest('access_decimal', `function func() { var arr = {flt:1.2}; return arr.flt; }`, '1.2')
    makeTest('access_exponent', `function func() { var arr = { exp : 3e2 }; return arr['exp']; }`, '300')
    makeTest('access_hex', `function func() { var arr = {hex:0xff}; return arr.hex; }`, '255')
    makeTest('access_binary', `function func() { var arr = {bin :0b11}; return arr["bin"]; }`, '3')
    makeTest('access_octal', `function func() { var arr = {oct:0o11}; return arr.oct; }`, '9')
    makeTest('access_string', `function func() { var arr = {str:'abc'}; return arr.str; }`, `abc`)
    makeTest('access_bool', `function func() { var arr = {bl:true}; return arr.bl; }`, `true`)
    makeTest('access_object', `function func() { var arr = {obj: {a:1, b: 'a'}}; return arr.obj.b; }`, `a`)
    makeTest('access_array', `function func() { var arr = {arr: [1, 'a']}; return arr.arr; }`, `[1,"a"]`)
    makeTest('access_array2', `function func() { var arr = {arr: [1, 'a']}; return arr.arr[0]; }`, `1`)
    makeTest('access_integer_multi', `function func() { var arr = {int1: 1,int2:2,int3:3}; return arr.int2; }`, '2')
    makeTest('access_decimal_multi', `function func() { var arr = {flt1: 1.2,flt2: 0.123,flt3: 12.040}; return arr.flt3; }`, '12.04')
    makeTest('access_exponent_multi', `function func() { var arr = {exp1:3e2,exp2:0e1,exp3:12e-3}; return arr['exp1']; }`, '300')
    makeTest('access_hex_multi', `function func() { var arr = {hex1:0xff,hex2:0x12,hex3:0x0b}; return arr.hex2; }`, '18')
    makeTest('access_binary_multi', `function func() { var arr = {bin1:0b11,bin2:0b00,bin3:0b10}; return arr.bin3; }`, '2')
    makeTest('access_octal_multi', `function func() { var arr = {oct1:0o11,oct2:0o70,oct3:0o77}; return arr.oct1; }`, '9')
    makeTest('access_string_multi', `function func() { var arr = {str1:'abc',str2:'',str3:'defg'}; return arr['str2']; }`, ``)
    makeTest('access_bool_multi', `function func() { var arr = {bl1:true,bl2:true,bl3:false}; return arr.bl3; }`, `false`)
    makeTest('access_all_multi', `function func() { var arr = {int:100, flt:2.3, exp:2e-1, hex:0xe91,bin:0b00,oct:0o071,str:' AFGg ', bl:true}; return arr.str; }`, ` AFGg `)
    makeTest('access_nest', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr.obj1; }`, `{"int":1,"flt":23.4}`)
    makeTest('access_nest2', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr.obj1.int; }`, `1`)
    makeTest('access_nest3', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr.obj1.flt; }`, `23.4`)
    makeTest('access_nest4', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr.obj2; }`, `{"str":"aa","str2":"bb"}`)
    makeTest('access_nest5', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr.obj2.str; }`, `aa`)
    makeTest('access_nest6', `function func() { var arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr.obj2.str2; }`, `bb`)
    makeTest('access_nest_multi', `function func() { var arr = {obj1:{int1:1,int2:23,int3:4},  obj2:{str1:"1", str2:"a", str3:"b"}, obj3:{obj4:{}, obj5:{int1:99}}}; return arr.obj3.obj5.int1; }`, `99`)
    makeTest('access_no_computed', `function func() { var arr = {int: 1}; return arr['int2']; }`, 'undefined')
    makeTest('access_no_property', `function func() { var arr = {int: 1}; return arr.int2; }`, 'undefined')
    makeTest('access_object_in-array-object', `function func() { var c = {a: [{b:3}, 2]}; return c.a[0].b; }`, `3`)
    makeTest('access_object_in-array-object2', `function func() { var c = {a: [{b:3, d:[1]}, 2]}; return c.a[0].d[0]; }`, `1`)
    makeTest('access_object-array-nest', `function func() { var c = {a:[{b:[1]}]}; return c.a[0].b[0]; }`, `1`)
    makeTest('declare_ref_integer', `function func() { var v0 = 0; var v1 = 1; var obj={num:v0,num2:v1}; return obj["num"] }`, '0')
    makeTest('declare_ref_decimal', `function func() { var v0 = 0.0; var v1 = 1.2; var obj={num:v0,num2:v1}; return obj['num2'] }`, '1.2')
    makeTest('declare_ref_bool', `function func() { var v0 = true; var v1 = false; var obj = {bl:v0,bl2:v1}; return obj.bl2}`, 'false')
    makeTest('declare_ref_string', `function func() { var v0 = ''; var v1 = 'abc'; var obj = {str:v0,str2:v1}; return obj.str2 }`, 'abc')
    makeTest('declare_ref_array', `function func() { var v0 = [1,2]; var v1 = 3; var obj = {arr:v0,num:v1}; return obj.arr[0] }`, '1')
    makeTest('declare_ref_object', `function func() { var v0 = { num:1, num2: 2}; var v1 = 3; var obj={obj:v0,num:v1}; return obj.obj.num2 }`, '2')
    makeTest('declare_ref_nest', `function func() { var v0 = [1,2]; var v1 = 1; var v2 = v0; var obj = {arr:v2,num:v1}; return obj.arr[1] }`, '2')
  })
  describe('assignment', function () {
    makeTest('assignment_empty', `function func() { var arr; arr = {}; return arr; }`, '{}')
    makeTest('assignment_integer', `function func() { var arr; arr = {int: 1}; return arr; }`, '{"int":1}')
    makeTest('assignment_copy', `function func() { var arr, arr2; arr = {int: 1, int:99}; arr2 = arr return arr2; }`, '{"int":99}')
    makeTest('assignment_object', `function func() { var arr; arr = {obj: {a:1, b: 'a'}}; return arr; }`, `{"obj":{"a":1,"b":"a"}}`)
    makeTest('assignment_array', `function func() { var arr; arr = {arr: [1, 'a']}; return arr; }`, `{"arr":[1,"a"]}`)
    makeTest('assignment_all_multi', `function func() { var arr; arr = {int:100, flt:2.3, exp:2e-1, hex:0xe91,bin:0b00,oct:0o071,str:' AFGg ', bl:true}; return arr; }`, `{"int":100,"flt":2.3,"exp":0.2,"hex":3729,"bin":0,"oct":57,"str":" AFGg ","bl":true}`)
    makeTest('assignment_nest', `function func() { var arr; arr = {obj1:{int:1,flt:23.4}, obj2:{str:"aa",str2:"bb"}}; return arr; }`, `{"obj1":{"int":1,"flt":23.4},"obj2":{"str":"aa","str2":"bb"}}`)
    makeTest('assignment_nest_multi', `function func() { var arr; arr = {obj1:{int1:1,int2:23,int3:4},  obj2:{str1:"1", str2:"a", str3:"b"}, obj3:{obj4:{}, obj5:{int1:99}}}; return arr; }`, `{"obj1":{"int1":1,"int2":23,"int3":4},"obj2":{"str1":"1","str2":"a","str3":"b"},"obj3":{"obj4":{},"obj5":{"int1":99}}}`)
    makeTest('assignment_ref_integer', `function func() { var v0 = 3; var v1 = 1; var obj={num:v0, num2:v1}; v0 = 99; return obj }`, '{"num":3,"num2":1}')
    makeTest('assignment_ref_decimal', `function func() { var v0 = 0.0; var v1 = 1.2 var obj ={num:v0,num2:v1}; v1 = 0.1; return obj.num }`, '0')
    makeTest('assignment_ref_bool', `function func() { var v0 = true; var v1 = false; var obj = {"bl":v0,"bl2":v1}; v1=true; return obj }`, '{"bl":true,"bl2":false}')
    makeTest('assignment_ref_string', `function func() { var v0 = ''; var v1 = 'abc'; var obj= {str:v0,str2: v1}; v1='efg'; return obj.str2; }`, 'abc')
    makeTest('assignment_ref_array', `function func() { var v0 = [1,2]; var v1 = 3; var obj={arr:v0, num:v1}; obj.arr[0]=99 return v0[0]}`, '99')
    makeTest('assignment_ref_object', `function func() { var v0 = { num:1, num2: 2}; var v1 = 3; var obj = {obj:v0,num:v1}; obj.obj.num=99 return v0.num}`, '99')
    makeTest('assignment_ref_nest', `function func() { var v1 = [1,2]; var v0 = { arr:v1, num2: 2}; var v2 = 3; var obj= {obj:v0, num:v2}; v1[1]=99 return obj.obj.arr[1] }`, '99')
    makeTest('assignment_ref_integer_reverse', `function func() { var v0 = 3; var v1 = 1; var obj ={num:v0, num2:v1}; obj.num = 99; return v0 }`, '3')
    makeTest('assignment_ref_decimal_reverse', `function func() { var v0 = 0.0; var v1 = 1.2 var obj={num:v0, num2:v1}; obj.num2 = 99.0; return v1 }`, '1.2')
    makeTest('assignment_ref_bool_reverse', `function func() { var v0 = true; var v1 = false; var obj= {bl:v0, bl2:v1}; obj.bl=false; return v0 }`, 'true')
    makeTest('assignment_ref_string_reverse', `function func() { var v0 = ''; var v1 = 'abc'; var obj= {str:v0,str2: v1}; obj.str='efg'; return v0; }`, '')
    makeTest('assignment_ref_array_reverse', `function func() { var v0 = [1,2]; var v1 = 3; var obj={arr:v0, num:v1}; obj.arr[0]=99 return v0[0]}`, '99')
    makeTest('assignment_ref_object_reverse', `function func() { var v0 = { num:1, num2: 2}; var v1 = 3; var obj= {obj:v0, num:v1}; obj.obj.num2=99; return v0.num2 }`, '99')
    makeTest('assignment_ref_nest_reverse', `function func() { var v1 = 3; var v0 = { num:v1, num2: 2}; var v2 = 3; var obj= {obj:v0, num:v2}; obj.obj.num=99 return v1 }`, '3')
    makeTest('assignment_ref_dup', `function func() { var v0 = { num:1, num2: 2}; var obj= {obj:v0, obj2:v0}; obj.obj.num=99 return obj }`, '{"obj":{"num":99,"num2":2},"obj2":{"num":99,"num2":2}}')
  })
  
  describe('update', function () {
    makeTest('update_property', `function func() { var arr = {}; arr.int = 1; return arr; }`, '{"int":1}')
    makeTest('update_property2', `function func() { var arr = {}; arr.int = 1; arr.str="abc" return arr; }`, '{"int":1,"str":"abc"}')
    makeTest('update_property_decimal', `function func() { var arr = {}; arr.dec = 1.2; return arr; }`, '{"dec":1.2}')
    makeTest('update_property_exponent', `function func() { var arr = {};  arr.exp=3e2; return arr; }`, '{"exp":300}')
    makeTest('update_property_hex', `function func() { var arr = {}; arr.hex = 0xff; return arr; }`, '{"hex":255}')
    makeTest('update_property_binary', `function func() { var arr = {}; arr.bin=0b11; return arr; }`, '{"bin":3}')
    makeTest('update_property_octal', `function func() { var arr = {}; arr.oct = 0o11; return arr; }`, '{"oct":9}')
    makeTest('update_property_string', `function func() { var arr = {}; arr.str = 'abc'; return arr; }`, `{"str":"abc"}`)
    makeTest('update_property_bool', `function func() { var arr = {}; arr.bl = true; return arr; }`, `{"bl":true}`)
    makeTest('update_property_object', `function func() { var arr = {}; arr.obj= {a:1, b: 'a'}; return arr; }`, `{"obj":{"a":1,"b":"a"}}`)
    makeTest('update_property_array', `function func() { var arr = {}; arr.arr = [1]; return arr; }`, `{"arr":[1]}`)
    makeTest('update_property_multi', `function func() { var arr = {}; arr.int=123;arr.flt=0.01;arr.str='AoB';arr.bl=true;arr.obj={a:1,b:['a']};arr.arr=['a',2];return arr; }`, '{"int":123,"flt":0.01,"str":"AoB","bl":true,"obj":{"a":1,"b":["a"]},"arr":["a",2]}')
    makeTest('update_property_2dim', `function func() { var arr; arr = {obj:{int:1}}; arr.arr=[2];arr.obj.int2=3; return arr; }`, `{"obj":{"int":1,"int2":3},"arr":[2]}`)
    makeTest('update_index_integer', `function func() { var arr = {int:0}; arr["int"] =111; return arr; }`, '{"int":111}')
    makeTest('update_index_decimal', `function func() { var arr = {dec:0}; arr["dec"] = 1.2; return arr; }`, '{"dec":1.2}')
    makeTest('update_index_exponent', `function func() { var arr = {exp:0};  arr['exp']=3e2; return arr; }`, '{"exp":300}')
    makeTest('update_index_hex', `function func() { var arr = {hex:0}; arr['hex'] = 0xff; return arr; }`, '{"hex":255}')
    makeTest('update_index_binary', `function func() { var arr = {bin:0}; arr["bin"] = 0b11; return arr; }`, '{"bin":3}')
    makeTest('update_index_octal', `function func() { var arr = {oct:0}; arr["oct"]=0o11; return arr; }`, '{"oct":9}')
    makeTest('update_index_string', `function func() { var arr = {str:0}; arr['str'] = 'abc'; return arr; }`, `{"str":"abc"}`)
    makeTest('update_index_bool', `function func() { var arr = {bl:0}; arr['bl']= [true]; return arr; }`, `{"bl":[true]}`)
    makeTest('update_index_object', `function func() { var arr = {obj:0}; arr['obj'] = {a:1, b: 'a'}; return arr; }`, `{"obj":{"a":1,"b":"a"}}`)
    makeTest('update_index_array', `function func() { var arr = {arr:0}; arr["arr"]=[1]; return arr; }`, `{"arr":[1]}`)
    makeTest('update_index_multi', `function func() { var arr = {int1:0,int2:1}; arr["int1"] =123;arr["int2"] =99;return arr; }`, '{"int1":123,"int2":99}')
    makeTest('update_index_2dim', `function func() { var arr; arr = {obj2:{int1:0,int2:1},obj3:{int3:2,int4:3}}; arr["obj3"]["int3"]=99;arr['obj2']["int1"]=88;arr['obj2']['int2']=77;arr['obj3']['int4']=66 return arr; }`, `{"obj2":{"int1":88,"int2":77},"obj3":{"int3":99,"int4":66}}`)
    makeTest('update_push_multidim', `function func() {
      var arr;
      arr = {
        obj2:{
          obj3:{
            obj4:{
              int:1,int2:23
            }
          },
          int3:4
        },
        obj5:{
          str:"1", arr:["a"]
        }
      };
      arr["obj5"]["str"]=99;
      arr['obj2']['obj3']["int3"]={ num: 88, str: "sss"};
      arr['obj2']["int3"]=[33,44];
      arr["arr"]=[222];
      return arr;
    }`,
    `{"obj2":{"obj3":{"obj4":{"int":1,"int2":23},"int3":{"num":88,"str":"sss"}},"int3":[33,44]},"obj5":{"str":99,"arr":["a"]},"arr":[222]}`)
  })
  makeTest('update_ref_integer', `function func() { var v0 = 3; var v1 = 1; var v3=99; var obj={num:v0, num2:v1}; obj.num = v3; return obj }`, '{"num":99,"num2":1}')
  makeTest('update_ref_decimal', `function func() { var v0 = 0.0; var v1 = 1.2; var v3=99.99 var obj={num:v0, num2:v1}; obj.num2 = v3; return obj.num2 }`, '99.99')
  makeTest('update_ref_bool', `function func() { var v0 = true; var v1 = false; var v2=true; var obj= {bl:v0, bl2:v1}; obj.bl2=v2; return obj.bl2 }`, 'true')
  makeTest('update_ref_string', `function func() { var v0 = ''; var v1 = 'abc'; var v2='efg' var obj= {str:v0,str2:v1}; obj.str=v2; return obj; }`, '{"str":"efg","str2":"abc"}')
  makeTest('update_ref_array', `function func() { var v0 = [1,2]; var v1 = 3; var v2=[3,4]; var obj ={arr:v0, num:v1}; obj.arr=v2 return obj.arr}`, '[3,4]')
  makeTest('update_ref_object', `function func() { var v0 = { num:1, num2: 2}; var v1 = 3; var v2={str:'a',str2:'b'}; var obj = {obj:v0, num:v1}; obj.obj.num=v2; return obj.obj }`, '{"num":{"str":"a","str2":"b"},"num2":2}')
  makeTest('update_ref_nest', `function func() { var v1 = 3; var v0 = { num:v1, num2: 2}; var v2 = [3,4]; var obj= {obj:v0, arr:v2}; obj.obj=v2 return obj }`, '{"obj":[3,4],"arr":[3,4]}')
});