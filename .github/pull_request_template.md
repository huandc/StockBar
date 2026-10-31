# Pull Request

## 概述 / Summary

<!-- 一两句话说清「改了什么」和「为什么改」。为什么比改了什么更重要。 -->

## 关联 Issue / Related issue

<!-- 例如 Closes #12;没有对应 Issue 就写 N/A -->

## 改动类型 / Type of change

- [ ] `feat` 新功能
- [ ] `fix` 缺陷修复
- [ ] `docs` 文档
- [ ] `refactor` / `perf` 重构或性能
- [ ] `test` 测试
- [ ] `build` / `ci` / `chore` 构建、CI、杂项

## 怎么验证的 / How has this been tested

<!-- 贴命令与结果,而不是「本地没问题」 -->

```bash
swift build
./scripts/test.sh
```

结果:

- `swift build`:
- 测试用例数 / 结果:

## 检查清单 / Checklist

- [ ] PR 标题符合 Conventional Commits:`type(scope): 描述`,`type` 为 `feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert`
- [ ] 新增/修改的逻辑有对应测试,或说明了不需要测试的理由
- [ ] 若完成 ROADMAP 中的条目,已勾选并补上「已完成」一行
- [ ] 没有提交无关文件(本地 `.build/`、`DerivedData`、编辑器配置等)
- [ ] 面向用户的变更已更新 README(如涉及设置项、占位符、安装方式)

## 截图 / Screenshots

<!-- 菜单栏或设置页的视觉变更请附上前后对比;纯逻辑改动可删掉本节 -->
