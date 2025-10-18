---
trigger: always_on
---

**最佳实践**
1. 动手干，不要空想
2. 要井井有条,遇到自己疑惑的地方不能妥协，慢下来，仔细搞
3. if it works, it works
4. 低复杂度，可替换，可复用的，拼积木
5. 70%可复用代码，30%胶水代码
6. code与data分离，将相关数据放在同一位置存储;gameplay 与 art 分离，不需美术也能做出玩法
7. code思路：先设计数据结构，再设计控制流程，再写具体的业务逻辑
8. timeline+eventSenquence
9. 以终为始：不过度设计，为效果服务，为用户服务。
10. 步骤分解，一步一步完成

**注意事项：非常重要，你经常犯病，你要严格按照下面说的来做！**
1. 所有的实现都要依据项目架构：derderClient/Content/Script/Core
2. 实现系统时，可以参考Coin系统的实现：
    - derderClient/Content/Script/DataLayer/Coin
    - derderClient/Content/Script/GameLayer/Coin

# 1. workspace:
> 关于工作区的文件夹，这是介绍：
- **derderClient**: 主项目代码所在地，包含完整的UE5项目结构和UnLua热更框架
- **UE5**: Unreal Engine 5.3源码，用于引擎级别的开发和调试
- **Script**: UnLua示例代码库，包含Lyra项目的Lua脚本实现，可作为开发参考
- **Note**: 记录的笔记，关于derderClient的相关文档和todo，可以参考里面的笔记内容作为开发依据

## 1.1 项目结构详解
```
derderClient/
├── Source/                    # C++源码目录
│   └── derderClient/         # 主模块源码
├── Content/                   # 游戏内容资源
│   ├── Script/               # Lua脚本目录
│   │   ├── Test/             # 测试脚本
│   │   └── LuaPanda.Lua      # 调试工具
│   ├── UI/                   # UI资源
│   │   ├── CommonWidgets/    # 通用UI组件
│   │   └── Menu/             # 菜单UI
│   └── Blueprints/           # 蓝图资源
├── Plugins/                   # 插件目录
│   ├── UnLua/                # 腾讯UnLua插件
│   ├── UnLuaExtensions/      # UnLua扩展插件
│   └── UnLuaTestSuite/       # UnLua测试套件
├── Config/                    # 配置文件
└── derderClient.uproject     # 项目文件
```

# 2. 项目介绍:
> 基于腾讯UnLua的热更方案设计的通用UE5框架，目的是为了快速开发与迭代游戏

## 2.1 技术栈
- **引擎**: Unreal Engine 5.3
- **热更方案**: 腾讯UnLua 2.3.6
- **脚本语言**: Lua 5.4.3/5.4.4
- **调试工具**: LuaPanda
- **扩展插件**: LuaSocket, LuaProtobuf, LuaRapidjson

## 2.2 核心特性
- **热更新**: 支持Lua脚本热更新，无需重新编译
- **跨平台**: 支持Win64, Mac, iOS, Android, Linux
- **调试支持**: 集成LuaPanda调试器，支持断点调试
- **扩展性**: 模块化设计，支持插件扩展
- **性能优化**: 基于反射的数据绑定和事件系统

# 3. 框架架构设计:
> 查看Note/架构介绍.md,这是你写代码的重要依据

# 4. 开发工作流
1. **创建蓝图**: 在UE编辑器中创建蓝图类
2. **绑定Lua**: 使用UnLua绑定Lua脚本到蓝图
3. **编写脚本**: 在`Content/Script/`目录下编写Lua脚本
4. **调试**: 使用LuaPanda进行断点调试
5. **热更新**: 修改脚本后自动热更新

# 5. unlua命名规范：
1. **lua类名**: 使用CamelCase命名，首字母大写，例如`MyClass`,但若是UE5的类，则使用UE5的命名规则，例如`UMyClass`
2. **lua类变量**: 私有：使用下划线开头，例如`_myVar`，公有：使用驼峰命名，例如`myVar`,但若是UE5的类，则使用UE5的命名规则，例如`ButtonTitile`
3. **lua类函数**: 私有：使用下划线开头，例如`_myFunc`，公有：使用驼峰命名，例如`myFunc`,但若是UE5的类，则使用UE5的命名规则，例如`Construct()`
4. 只有重写ue的函数/变量的public类型才大写，其他的都小写，然后基于是否私有来加'_'
5. 在GameLayer和DataLayer文件夹中的类名大写即可

示例：
``` lua
---@type BP_CoreGame_C
local M = UnLua.Class()

-- 继承UE5的类
function M:Initialize(Initializer)
    self.publicVar = "这是公共变量"  -- 公共成员
    self._privateVar = "这是私有变量"  -- 私有成员（通过下划线前缀约定）
end

function M:publicMethod()  -- 公共方法
    print("公共方法")
end

function M:_privateMethod()  -- 私有方法（通过下划线前缀约定）
    print("私有方法")
end

return M
```
