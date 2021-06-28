

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'fy_anno.dart';

class TestGenerator extends GeneratorForAnnotation<ParamMetadata> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    print("===========================${element.name}=start===============================");
    //含注解类的基本信息
    print("element.name:${element.name}");
    print("element.toString:${element.toString()}");
    //关注 kind 属性值： element.kind: CLASS，kind 标识 Element 的类型，可以是 CLASS、	 //FIELD、FUNCTION 等等
    print("element.kind:${element.kind}");
    print("element.enclosingElement:${element.enclosingElement}");
    print("element.metadata:${element.metadata}");
    //注解的相关信息
    print("annotation.runtimeType:${annotation.runtimeType}");
    print("annotation.read('name'):${annotation.peek("name").stringValue}");
    print("annotation.read('id'):${annotation.peek("id").intValue}");
    print("annotation.objectValue:${annotation.objectValue}");
    //解析类的字段和方法
    if(element.kind == ElementKind.CLASS){
      for (var e in ((element as ClassElement).fields)) {
        print("$e \n");
      }
      for (var e in ((element as ClassElement).methods)) {
        print("$e \n");
      }
    }
    //输入相关信息
    print("buildStep.inputId.path:${buildStep.inputId.path}");
    print("buildStep.inputId.extension:${buildStep.inputId.extension}");
    print("buildStep.inputId.package:${buildStep.inputId.package}");
    print("===========================${element.name}=end===============================");
    return "class ${element.name}{}";
  }
}