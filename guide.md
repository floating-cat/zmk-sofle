# 如何使用 Nix 进行构建

## 环境初始化

1. 进入项目目录，运行：
   ```bash
   direnv allow
   ```

2. 初始化环境：
   ```bash
   just init
   ```

## 构建固件

运行以下命令构建全部固件：

```bash
just build all
```

构建完成后，固件会生成在 `firmware` 目录下。

### 构建失败处理

如果执行 `just build all` 失败，但确认配置文件没有问题，可以尝试删除构建缓存后重试：

```bash
rm -rf .build
```

## 其他构建方式

### 方式一：GitHub Actions 自动构建

每次推送到 GitHub 仓库时，会自动触发 Actions 进行构建。

如果不使用该方式，建议修改 `.github/workflows/build.yml`，将以下内容注释掉：

```yaml
push:
  paths-ignore:
    - "keymap-drawer/"
```

### 方式二：GitHub Actions 手动构建

打开 GitHub 该项目的 Actions 标签页，点击 `Build ZMK firmware` 或者 `Build ZMK firmware (nix)
` 进行构建。

---

## 如何后续更新项目依赖

- 更新 ZMK 仓库及 ZMK 相关依赖模块：
  ```bash
  just update
  ```

- 更新 Nix 相关依赖：
  ```bash
  just upgrade-sdk
  ```

更多 Nix 使用方式可以参考：https://github.com/urob/zmk-config?tab=readme-ov-file#local-build-environment (本项目的 Nix 脚本基于该项目)


---

## 键盘布局图片更新方式

### 方式一：本地生成

```bash
just draw
```

来手动更新 keymap-drawer/eyelash_sofle.svg

### 方式二：GitHub Actions 自动生成

每次推送到 GitHub 时，会自动更新键盘布局图片，并自动 commit 一条 `[Draw] 之前的提交信息` 提交到仓库。

如果不使用该方式，建议修改 `.github/workflows/draw.yml`，将以下内容注释掉：

```yaml
push:
  paths:
    - "config/"
    - .github/workflows/draw.yml
    - keymap-drawer/keymap_drawer.config.yaml
```

---

## 项目说明

该项目基于原始键盘仓库：
- 添加了 Nix 支持
- 删除了一些不必要的内容

## 后续优化建议

### 1. 配置文件优化

文件：`config/eyelash_sofle.conf`

很多参数可能无用或为默认值，可以建议清理精简。参考配置（可能已过时）：https://github.com/floating-cat/zmk-config-eyelash-sofle-corne/blob/main/config/eyelash_sofle.conf

### 2. Keymap 优化

文件：`config/eyelash_sofle.keymap`

一些地方写的比较差，建议参考 ZMK 的官方文档根据自己的需求改写一下。比如说每层的名字像是 layer0 layer_1 太差了，完全可以改成 Base Num Nav 之类更有意义的名字。

### 3. Keymap Drawer 优化

文件：
- `keymap-drawer/eyelash_sofle.json`
- `keymap-drawer/keymap_drawer.config.yaml`

可以参考 https://github.com/caksoylar/keymap-drawer 来优化这两个文件，比如说可以把一些按键的名字改成自己想要的名字，把没必要的配置项、样式去掉之类的。
