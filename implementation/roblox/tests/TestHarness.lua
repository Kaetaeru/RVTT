--!strict
local Harness={};Harness.__index=Harness
function Harness.new()return setmetatable({passed=0,failed=0,failures={}},Harness)end
function Harness:expect(condition:boolean,message:string)if condition then self.passed+=1 else self.failed+=1;table.insert(self.failures,message)end end
function Harness:equal(actual,expected,message)self:expect(actual==expected,(message or"values differ").." expected="..tostring(expected).." actual="..tostring(actual))end
return Harness
