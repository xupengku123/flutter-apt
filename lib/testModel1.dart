

import 'fy_anno.dart';

@TestMetadata()
class TestModel {}

@ParamMetadata("test", 1)
class TestModel1V1{
  @ParamMetadata("Localage", 1)
  int age;
  int bookNum;

  @ParamMetadata("LocalFun1", 1)
  void fun1() {}

  void fun2(int a) {}
}

@ParamMetadata("test1v2", 12)
class TestModel1V2{
  int age;
  int bookNum;
  void fun1() {}

  void fun2(int a) {}
}

@ParamMetadata("testValue", 2)
int memberValue=0;

@ParamMetadata("testMemberFun", 3)
void memberFun(){

}