### 1、背景

最近在项目中使用到了Dart中的注解代码生成技术json_serializable库。这跟javaAPT+JavaPoet生成代码技术有何不同？需要解决的问题：

- dart中如何定义和使用注解？

- Flutter中在禁用了dart:mirror，无法使用反射情况下如何得到类相关信息？

- 提取到注解信息时又是如何生成复杂的模板代码?

  

  带着以上问题我们来探究dart中注解生成代码技术

  

  ### 2.注解的创建和使用

  - 比起 java 中的注解创建，Dart 的注解创建更加朴素，没有多余的关键字，没有元注解。实际上只是一个构造方法需要修饰成 const 的普通 Class 。

  - Dart的注解创建和普通的class创建没有任何区别，可以 extends, 可以 implements ，甚至可以 with。唯一必须的要求是：**构造方法需要用 const 来修饰**
  - 不同于java注解的创建需要指明@Target（定义可以修饰对象范围）。Dart 的注解没有修饰范围，定义好的注解可以修饰类、属性、方法、参数

  

  例如，申明一个没有参数的注解：

```dart
class TestMetadata {
  const TestMetadata();
}
```

使用：

```dart
@TestMetadata()
class TestModel {}
```

申明一个有参数的注解：

```dart
class ParamMetadata {
  final String name;
  final int id;

  const ParamMetadata(this.name, this.id);
}
```

使用：

```dart
@ParamMetadata("test", 1)
class TestModel {
  int age;
  int bookNum;
  void fun1() {}

  void fun2(int a) {}
}

```

只有注解没什么意义，需要对注解进行处理

### 3.Dart 注解处理以及代码生成

Flutter中,也就是Dart的注解处理依赖于 [source_gen](https://github.com/dart-lang/source_gen).相当于java中的apt，可以拦截和处理注解。

1.第一步，在你工程的 pubspec.yaml 中引入 source_gen

```dart
dependencies:
  source_gen:
```

source_gen是基于build` 包的，同时提供暴露了一些选项以方便在一个 `Builder` 中使用你自己的生成器 `Generator。

因此还需要引入build和build_runner

```dart
dependencies:
  build:
  
dev_dependencies:
  build_runner: 
```

2.创建生成器

- 你需要创建一个 Generator，继承于 GeneratorForAnnotation, 并实现： generateForAnnotatedElement 方法
- 还要在 GeneratorForAnnotation 的泛型参数中填入我们要拦截的注解

```dart
class TestGenerator extends GeneratorForAnnotation<TestMetadata> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    return "class Tessss{}";
  }
}
```

返回值是一个 String，其内容就是你将要生成的代码。

你可以通过 generateForAnnotatedElement 方法的三个参数获取注解的各种信息，可以用来生成相对应的代码。这里我们仅简单的返回一个字符串 "class Tessss{}"，用来看看效果。

```dart
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
```

3.创建Builder

Generator 的执行需要 Builder 来触发，所以现在我们要创建一个Builder。

只需要创建一个返回类型为 Builder 的全局方法即可：

```dart
Builder testBuilder(BuilderOptions options) =>
    LibraryBuilder(TestGenerator());

```

根据不同的需求，我们还有其他Builder对象可选，Builder 的继承树：

Builder

- _Builder
  - PartBuilder
  - LibraryBuilder
  - SharedPartBuilder

PartBuilder 与 SharedPartBuilder 涉及到 dart-part 关键字的使用，这里我们暂时不做展开，通常情况下 LibraryBuilder 已足以满足我们的需求

4.在项目根目录创建 build.yaml 文件，其意义在于 配置 Builder 的各项参数：

```dart
builders:
  testBuilder:
    import: "package:flutter_annotation/test.dart"
    builder_factories: ["testBuilder"]
    build_extensions: {".dart": [".g.part"]}
    auto_apply: root_package
    build_to: source
```

配置信息的详细含义我们后面解释。重点关注的是，通过 import 和 builder_factories 两个标签，我们指定了上一步创建的 Builder。

5.运行 Builder

命令行中执行命令，运行我们的 Builder

flutter packages pub run build_runner build --delete-conflicting-outputs   //build的命令

受限于Flutter 禁止反射的缘故，你不能像Android中使用编译时注解那样，在编译阶段生成类，运行阶段通过反射创建类对象。在Flutter中，你只能先通过命令生成代码，然后再直接使用生成的代码。因此Flutter注解目前只能在开发阶段生成一些重复性的代码，其实java官方也是不推荐我们使用反射代码的。

不出意外的话，命令执行成功后将会生成一个新的文件：TestModel.g.dart 其内容：

```
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// TestGenerator
// **************************************************************************

class Tessss {}


```

清理生成的文件无需手动删除，可执行以下命令：

```
flutter packages pub run build_runner clean //清理自动生成的文件
```

### 4.代码生成API的详解

1.如果你的 Generator 直接继承自 GeneratorForAnnotation， **那你的 Generator 只能拦截到 top-level 级别的元素，对于类内部属性、方法等无法拦截**，类内部属性、方法修饰注解暂时没有意义。（不过这个扩展一下肯定可以实现的）

2.GeneratorForAnnotation与annotation的对应关系

GeneratorForAnnotation是单注解处理器，每一个 GeneratorForAnnotation 必须有且只有一个 annotation 作为其泛型参数。也就是说每一个继承自GeneratorForAnnotation的生成器只能处理一种注解。如果同时处理多种注解，就要定义多个注解处理器。

3.generateForAnnotatedElement 参数含义（见打印信息）

- Element element：被 annotation 所修饰的元素，通过它可以获取到元素的name、可见性等等。

- ConstantReader annotation：表示注解对象，通过它可以获取到注解相关信息以及参数值。

- BuildStep buildStep：这一次构建的信息，通过它可以获取到一些输入输出信息，例如输入文件名等

generateForAnnotatedElement 的返回值是一个 String，你需要用字符串拼接出你想要生成的代码，`return null` 意味着不需要生成文件

4.代码与文件生成规则

不同于java apt，文件生成完全由开发者自定义。GeneratorForAnnotation 的文件生成有一套自己的规则。

如果 generateForAnnotatedElement 的返回值 不为空，则：

- 若一个源文件仅含有一个被目标注解修饰的类，**则每一个包含目标注解的文件，都对应一个生成文件；**

- 若一个源文件含有多个被目标注解修饰的类，**则生成一个文件，generateForAnnotatedElement方法被执行多次，生成的代码通过两个换行符拼接后，输出到该文件中。**

5.模板代码生成技巧

5.1 简单模板代码，字符串拼接：

如果需要生成的代码不是很复杂，则可以直接用字符串进行拼接，比如这样：

```dart
generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    ...
    StringBuffer codeBuffer = StringBuffer("\n");
    codeBuffer..write("class ")
      ..write(element.name)
      ..write("_APT{")
      ..writeln("\n")
      ..writeln("}");
    
    return codeBuffer.toString();
  }

```

不过一般情况下我们并不建议这样做，因为这样写起来太容易出错了，且不具备可读性。

5.2复杂模板代码，dart 多行字符串+占位符

dart提供了一种三引号的语法，用于多行字符串。结合占位符后，可以实现比较清晰的模板代码:

```dart
tempCode(String className) {
    return """
      class ${className}APT {
 
      }
      """;
  }
  
generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    ...
    return tempCode(element.name);
  } 


```

这种方式生成的代码可读性比较高

5.3 其他第三方生成代码的库

- mustach  预制模板，通过一定的规则，提取信息之后填充信息到模板中，学习成本较低，适合一些固定格式的代码生成，比如路由表，阿里的annotation_route框架就是采用这个，可以看下它的模板
- [code_builder](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fcode_builder)非常强大，类似java注解生成代码的javapoet。学习成本较高且可读性不强（不推荐）

### 5.配置文件字段含义

在工程根目录下创建`build.yaml` 文件，用来配置Builder相关信息。

以下面配置为例：

```dart
builders:
  test_builder:
    import: 'package:flutter_annotation/test_builder.dart'
    builder_factories: ['testBuilder']
    build_extensions: { '.dart': ['.g1.dart'] }
    required_inputs:['.dart']
    auto_apply: root_package
    build_to: source

  test_builder2:
    import: 'package:flutter_annotation/test_builder2.dart'
    builder_factories: ['testBuilder2']
    build_extensions: { '.dart': ['.g.dart'] }
    auto_apply: root_package
    runs_before: ['flutter_annotation|test_builder']
    build_to: source

```

在`builders` 下配置你所有的builder。test_builder与 test_builder2 均是你的builder命名。

- import 关键字用于导入 return Builder 的方法所在包 （必须）

- builder_factories 填写的是我们 return Builder 的方法名（必须）

- build_extensions  指定输入扩展名到输出扩展名的映射，比如我们接受`.dart`文件的输入，最终输出`.g.dart` 文件（必须）

- auto_apply 指定builder作用于，可选值：  （可选，默认为 none）

  - "none"：除非手动配置，否则不要应用此Builder
  - "dependents"：将此Builder应用于包，直接依赖于公开构建器的包。
  - "all_packages"：将此Builder应用于传递依赖关系图中的所有包。
  - "root_package"：仅将此Builder应用于顶级包。

- build_to 指定输出位置,可选值： （可选，默认为 cache）

  - "source": 输出到其主要输入的源码树上
  - "cache": 输出到隐藏的构建缓存上

- required_inputs  指定一个或一系列文件扩展名，表示在任何可能产生该类型输出的Builder之后运行。不能指定为该builder也会产生的输出，这将导致自循环（可选）

- runs_before 保证在指定的Builder之前运行 类似gradle里的task


  更多的配置信息详见官方说明[build_config](https://links.jianshu.com/go?to=https%3A%2F%2Fpub.dev%2Fpackages%2Fbuild_config)

  build.yaml 配置的信息，最终都会被 build_config.dart 中的 BuildConfig 类读取到

  ![image-20210614192151001](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210614192151001.png)

从build_config.dart中可以看到，主要解析4个大的部分，下面将挑选常用的2个进行分析

![image-20210614220343440](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210614220343440.png)

##### 5.1targets:

在 build_target.dart#BuildTarget 可以看到支持属性的描述，其中有个builder属性使用的比较多

![image-20210614220613025](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210614220613025.png)

在TargetBuilderConfig中有3个常用的属性:

- enable

当前builder是否生效

- generate_for

这个属性比较重要，可以决定针对那些文件/文件夹做扫描，或者排除哪些文件，例如：

![image-20210615101945181](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210615101945181.png)

- options

这个属性可以允许你以键值对形式携带一些配置数据到代码生成器中,options里配置的属性可以被devOptions或者releaseOptions里的属性覆盖

![image-20210615102133866](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210615102133866.png)



5.2builder

![image-20210615102825297](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210615102825297.png)

上面是创建builder

![image-20210615103014467](C:\Users\ForU\AppData\Roaming\Typora\typora-user-images\image-20210615103014467.png)

Map<String, BuilderDefinition> 即 BuilderDefinition 信息，下面将介绍一下常用的配置

![img](https://upload-images.jianshu.io/upload_images/13183175-dad5683ea199b80a.png?imageMogr2/auto-orient/strip|imageView2/2/w/980/format/webp)



### 6.关于source_gen

[source_gen](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsource_gen)基于官方的 [analysis](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsdk%2Fblob%2Fmaster%2Fpkg%2Fanalyzer%2FREADME.md)/[build](https://links.jianshu.com/go?to=https%3A%2F%2Fpub.dev%2Fpackages%2Fbuild)提供了一系列友好的封装，source_gen 基于 analyzer 和 build 库，其中

- build库主要是资源文件的处理
- analyser库是对dart文件生成语法结构
   source_gen主要是处理dart源码，可以通过注解生成代码。

source_gen从build库提供的Builder派生出自己的_builder，并且封装了3个

• SharedPartBuilder

生成.g.dart文件，类似json_seriable一样，使用地方需要用是part of引用，这样有个最大的好处就是引用问题不需要过于关注，要注意的是，需要使用      source_gen|combining_builder，它会将所有.g文件进行合并。

• LibraryBuilder
 生成独立的文件
 • PartBuilder
 自定义part文件

source_gen封装了一套Generator，上面的buidler接收Generator的集合,收集Generator的产出生成一份文件，Generator只是一个抽象类，具体实现类是GeneratorForAnnotation，默认只能拦截到***top-level\***级别的元素，会被注解生成器接受一个指定注解类型，即GeneratorForAnnotation是单注解处理器

由analyser提供了语法节点的抽象元素Element和其metadata字段，对应Element Annotation，注解生成器可以检查元素的metadata类型是否匹配声明的注解类型，从而找出被注解的元素及元素所在上下文的信息，然后将这些信息包装给使用者。

##### 1.核心的 Generator

Generator源码很简单：

```dart
abstract class Generator {
  const Generator();

  /// Generates Dart code for an input Dart library.
  ///
  /// May create additional outputs through the `buildStep`, but the 'primary'
  /// output is Dart code returned through the Future. If there is nothing to
  /// generate for this library may return null, or a Future that resolves to
  /// null or the empty string.
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) => null;

  @override
  String toString() => runtimeType.toString();
}

```

就这么几行代码，在 Builder 运行时，会调用 Generator 的 `generate`方法，并传入两个重要的参数：

- `library` 通过它，我们可以获取源代码信息以及注解信息
- `buildStep` 它表示构建过程中的一个步骤，通过它，我们可以获取一些文件的输入输出信息

值得注意的是，library 包含的源码信息是一个个的 Element 元素，这些 Element 可以是Class、可以是function、enums等等。

ok，让我们再来看看 `source_gen` 中，Generator 的唯一子类 ：GeneratorForAnnotation 的源码：

```dart
abstract class GeneratorForAnnotation<T> extends Generator {
  const GeneratorForAnnotation();

  //1   typeChecker 用来做注解检查
  TypeChecker get typeChecker => TypeChecker.fromRuntime(T);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    var values = Set<String>();

    //2  遍历所有满足 注解 类型条件的element
    for (var annotatedElement in library.annotatedWith(typeChecker)) {
      //3 满足检查条件的调用 generateForAnnotatedElement 执行开发者自定义的代码生成逻辑
      var generatedValue = generateForAnnotatedElement(
          annotatedElement.element, annotatedElement.annotation, buildStep);
          //4 generatedValue是将要生成的代码字符串，通过normalizeGeneratorOutput格式化
      await for (var value in normalizeGeneratorOutput(generatedValue)) {
        assert(value == null || (value.length == value.trim().length));
        //5 生成的代码加入集合
        values.add(value);
      }
    }
	//6
    return values.join('\n\n');
  }
	
	//7
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep);

```

//1 : typeChecker 用来做注解检查,效验Element上是否修饰了目标注解

//2 : library.annotatedWith(typeChecker) 会遍历所有的 Element，并通过typeChecker检查这些Element 是否修饰了目标注解。**值得再次说明的是：`library.annotatedWith` 遍历的 Element 仅包括top-level级别的 Element，也就是那些文件级别的 Class、function等等，而Class 内部的 fields、functions并不在遍历范围，如果在 Class 内部的fields 或 functions 上修饰注解，GeneratorForAnnotation并不会拦截到！**

//3 : 满足条件后，调用`generateForAnnotatedElement`方法，也就是我们自定义Generator所实现的抽象方法。

//4 : generatedValue 是`generateForAnnotatedElement`返回值，也是我们要生成的代码，调用`normalizeGeneratorOutput`去做格式化。

//5 : 满足条件后，添加到集合`values`当中。**值得再次说明的是: 之前我们也提到过，当返回值不为空的情况下，每一个文件输入源对应着一个文件输出。也就是说源码中，每一个`\*.dart`文件都会触发一次`generate`方法调用，而其中每一个符合条件的目标注解使用，都会触发一次`generateForAnnotatedElement` 调用，如果被多次调用，多个返回值最终会拼接起来，输出到一个文件当中。**

//6 : 每个单独的输出之间用两个换行符分割，最终输出到一个文件当中。

//7 : 我们自定义Generator所实现的抽象方法。

##### 2.library.annotatedWith 源码浅析\

```dart
class LibraryReader {
  final LibraryElement element;
  LibraryReader(this.element);

  ...

  //1 所有Element，但仅限top-level级别
  Iterable<Element> get allElements sync* {
    for (var cu in element.units) {
      yield* cu.accessors;
      yield* cu.enums;
      yield* cu.functionTypeAliases;
      yield* cu.functions;
      yield* cu.mixins;
      yield* cu.topLevelVariables;
      yield* cu.types;
    }
  }

  Iterable<AnnotatedElement> annotatedWith(TypeChecker checker,
      {bool throwOnUnresolved}) sync* {
    for (final element in allElements) {
      //2 如果修饰了多个相同的注解，只会取第一个
      final annotation = checker.firstAnnotationOf(element,
          throwOnUnresolved: throwOnUnresolved);
      if (annotation != null) {
        //3 将annotation包装成AnnotatedElement对象返回
        yield AnnotatedElement(ConstantReader(annotation), element);
      }
    }
  }


```

//1 : 这里的 allElements 仅限top-level级别的子Element

//2 : 这里会借助 checker 检查 Element 所修饰的注解，如果修饰了多个相同的注解，只会取第一个，如果没有目标注解，则返回null

//3 : 返回的 annotation 实际只是一个 `DartObject` 对象，可以通过这个对象来取值，但为了便于使用，这里要将它再包装成API更友好的AnnotatedElement，然后返回。



### 7.与Java注解生成代码对比

![img](https://upload-images.jianshu.io/upload_images/13183175-46254444b77d40f2.png?imageMogr2/auto-orient/strip|imageView2/2/w/1107/format/webp)

### 8.总结

本文初步探索了在Dart通过注解生成代码的技术，比起java的apt，没有运行时反射用起来还是有点点麻烦，需要手动执行build，而且各种繁琐的builder配置，让人感觉晦涩难懂，生成代码的技巧也跟java有着异曲同工之妙，需要借助一些外力比如mustach,code_builder等。这种技术给我们在解决一些例如路由，模板代码、动态代理等，多了一种处理手段，其他更多的使用场景需要我们去开发中慢慢探索



### 参考

- [详解Dart中如何通过注解生成代码](https://www.jianshu.com/p/aa6cc00cb76d)
- [source_gen](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsource_gen)
- [Flutter 注解处理及代码生成](https://links.jianshu.com/go?to=https%3A%2F%2Fjuejin.im%2Fpost%2F5d1ac884f265da1bad571f3a%23heading-7)
- [mustache](https://links.jianshu.com/go?to=http%3A%2F%2Fmustache.github.io%2Fmustache.5.html)


