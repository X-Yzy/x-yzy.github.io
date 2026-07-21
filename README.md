# Chirpy 博客｜上传发布版

此压缩包用于上传到 **GitHub Pages 仓库**。它只包含发布需要的源码、文章和 GitHub Actions，不包含本地预览脚本、草稿目录和本地缓存。

## 一、先修改个人信息

打开 `_config.yml`，替换以下占位符：

- `YOUR_GITHUB_USERNAME`：GitHub 用户名
- `YOUR_NAME`：显示名称
- `YOUR_EMAIL@example.com`：邮箱

重点确认：

```yaml
title: YOUR_NAME 的安全笔记
url: "https://YOUR_GITHUB_USERNAME.github.io"

github:
  username: YOUR_GITHUB_USERNAME
```

头像文件为：

```text
assets/img/avatar.svg
```

可以替换为自己的头像，然后修改 `_config.yml` 中的 `avatar`。

## 二、创建 GitHub Pages 仓库

仓库名称必须是：

```text
你的GitHub用户名.github.io
```

仓库建议设置为 `Public`。

## 三、手动上传

在 GitHub 仓库页面点击：

```text
Add file → Upload files
```

将本压缩包解压后的**所有文件和隐藏目录**上传到仓库根目录，包括：

```text
.github
_config.yml
_posts
_tabs
assets
Gemfile
```

不要只上传压缩包本身。

## 四、启用 GitHub Pages

进入：

```text
Settings → Pages → Build and deployment → Source → GitHub Actions
```

再到 `Actions` 页面查看构建。成功后访问：

```text
https://你的GitHub用户名.github.io
```

## 五、写文章

文章放入 `_posts`，文件名格式：

```text
2026-07-21-article-name.md
```

文章示例：

```yaml
---
title: Docker 环境搭建记录
date: 2026-07-21 20:00:00 +0800
categories: [环境搭建, Docker]
tags: [Docker, Linux]
description: 记录 Docker 环境的安装过程。
---
```

主分类已经预设为：环境搭建、Web安全、内网渗透、免杀钓鱼、随笔。

## 普通 Nginx/宝塔服务器说明

这个包是 **Jekyll 源码包**，适合 GitHub Pages 或具备 Ruby/Jekyll 构建环境的服务器。普通 Nginx 静态站点不能直接解析这些源码。

若要上传普通服务器，请使用“本地预览版”中的 `构建静态站点.bat` 或 `scripts/build-static.sh`，然后只上传生成的 `_site` 目录内容。
