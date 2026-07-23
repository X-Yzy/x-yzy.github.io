---
title: Java 反射与动态代理：核心 API 与实现示例
date: 2026-07-22 15:30:00 +0800
categories: [Java, 基础机制, 反射与代理]
tags: [Java, 反射, 动态代理]
description: 梳理 Java 反射常用 API，并通过完整示例理解 JDK 动态代理的创建方式与调用流程。
toc: true
---

Java 反射允许程序在运行时获取类的信息并操作对象；JDK 动态代理则建立在反射之上，可以在不修改目标类的情况下增强方法调用。

本文记录两者的常用写法、关键区别和容易踩到的问题。

## 动态代理

JDK 动态代理主要包含三个角色：

- **接口**：定义代理对象对外提供的能力。
- **目标对象**：实现真实业务逻辑。
- **调用处理器**：在目标方法执行前后插入附加逻辑。

### 定义接口

```java
package com.yzy.proxy;

public interface Star {
    String sing(String song);

    void dance();
}
```

接口中的方法默认就是 `public abstract`，因此可以省略这两个修饰符。

### 实现目标类

```java
package com.yzy.proxy;

public class BigStar implements Star {
    private String name;

    public BigStar(String name) {
        this.name = name;
    }

    @Override
    public String sing(String song) {
        System.out.println(name + " is singing " + song);
        return song;
    }

    @Override
    public void dance() {
        System.out.println(name + " is dancing");
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
```

### 创建代理对象

```java
package com.yzy.proxy;

import java.lang.reflect.Proxy;

public final class ProxyUtil {
    private ProxyUtil() {
    }

    public static Star createProxy(Star target) {
        return (Star) Proxy.newProxyInstance(
                target.getClass().getClassLoader(),
                target.getClass().getInterfaces(),
                (proxy, method, args) -> {
                    if ("sing".equals(method.getName())) {
                        System.out.println("ProxyUtil: preparing to sing " + args[0]);
                    } else {
                        System.out.println("ProxyUtil: calling " + method.getName());
                    }

                    return method.invoke(target, args);
                }
        );
    }
}
```

`Proxy.newProxyInstance()` 的三个核心参数分别是：

1. 用于加载代理类的类加载器；
2. 代理类需要实现的接口数组；
3. 负责处理所有方法调用的 `InvocationHandler`。

### 调用代理

```java
package com.yzy.proxy;

public class ProxyDemo {
    public static void main(String[] args) {
        Star target = new BigStar("X_Y");
        Star proxy = ProxyUtil.createProxy(target);

        String result = proxy.sing("Hello");
        System.out.println("result: " + result);
        proxy.dance();
    }
}
```

运行结果类似：

```text
ProxyUtil: preparing to sing Hello
X_Y is singing Hello
result: Hello
ProxyUtil: calling dance
X_Y is dancing
```

JDK 动态代理只能直接代理接口。如果目标类没有实现接口，通常需要使用基于子类生成的代理方案。

## 反射

下面的示例假设存在一个 `Student` 类，其中包含 `name`、`age` 字段，以及相应的方法和构造器。

### 获取 Class 对象

```java
// 方式一：通过类的完整名称
Class<?> clazz1 = Class.forName("com.yzy.reflect.Student");

// 方式二：通过类字面量
Class<Student> clazz2 = Student.class;

// 方式三：通过对象实例
Student student = new Student("yzy");
Class<?> clazz3 = student.getClass();

Object instance = clazz1.getDeclaredConstructor().newInstance();
System.out.println(instance.getClass().getName());
```

三种方式获得的是同一个类对应的 `Class` 对象，但适用场景不同：

- `Class.forName()` 适合类名在运行时才能确定的场景；
- `类名.class` 写法清晰，并且在编译期即可检查；
- `对象.getClass()` 适合已经持有实例的场景。

### 获取字段

```java
Class<Student> clazz = Student.class;
Student student = new Student("yzy");

// 获取公共字段，包括继承得到的字段
Field[] publicFields = clazz.getFields();

// 获取当前类声明的全部字段，不包含继承字段
Field[] declaredFields = clazz.getDeclaredFields();

Field nameField = clazz.getDeclaredField("name");
nameField.setAccessible(true);

System.out.println(nameField.getName() + " = " + nameField.get(student));
nameField.set(student, "X_Y");
```

### 获取并调用方法

```java
Method[] publicMethods = clazz.getMethods();
Method[] declaredMethods = clazz.getDeclaredMethods();

Method getName = clazz.getMethod("getName");
Method setName = clazz.getDeclaredMethod("setName", String.class);

Object before = getName.invoke(student);
setName.invoke(student, "yzy111");
Object after = getName.invoke(student);

System.out.println(before + " -> " + after);
```

`invoke()` 的第一个参数是目标对象，后续参数会传递给被调用的方法。静态方法的目标对象可以传入 `null`。

### 获取并调用构造器

```java
Constructor<?>[] publicConstructors = clazz.getConstructors();
Constructor<?>[] declaredConstructors = clazz.getDeclaredConstructors();

Constructor<Student> constructor = clazz.getDeclaredConstructor(String.class);
constructor.setAccessible(true);

Student created = constructor.newInstance("yzy");
System.out.println(created.getName());
```

如果使用非公共成员，在较新的 Java 模块系统中，`setAccessible(true)` 可能受到模块边界限制，并抛出 `InaccessibleObjectException`。

## 常用 API 对照

| 目标 | 公共成员（含继承） | 当前类声明的成员 |
| --- | --- | --- |
| 字段 | `getFields()` | `getDeclaredFields()` |
| 方法 | `getMethods()` | `getDeclaredMethods()` |
| 构造器 | `getConstructors()` | `getDeclaredConstructors()` |

## 注意事项

- 反射会绕过一部分编译期检查，异常处理和参数类型需要格外谨慎。
- 被调用方法抛出的异常会被包装为 `InvocationTargetException`。
- 不要在性能敏感的循环中重复查找同一个反射对象，可以提前缓存。
- 对非公共成员进行强制访问会增加代码对 JDK 版本和模块配置的依赖。

## 小结

反射解决的是“运行时认识并操作类型”的问题，动态代理解决的是“统一拦截并增强接口调用”的问题。理解 `Class`、`Method`、`Constructor` 和 `InvocationHandler` 之间的关系，是继续学习 Java 框架机制与安全分析的基础。
