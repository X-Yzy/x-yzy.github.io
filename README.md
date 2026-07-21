# X_Y 的安全笔记

基于 Jekyll 构建的个人技术博客，主要记录环境搭建、安全研究、问题排查和学习复盘。

## 目录

- `_posts`：博客文章
- `_tabs`：导航页面
- `assets`：图片等静态资源
- `_config.yml`：站点配置

## 本地运行

需要 Ruby 和 Bundler：

```console
bundle install
bundle exec jekyll serve
```

推送到主分支后，GitHub Actions 会自动构建并发布站点。
