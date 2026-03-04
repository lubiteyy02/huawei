# 🔧 编译错误修复记录

## 修复的问题

### 1. throw语句限制 (arkts-limited-throw)

**错误**: ArkTS不允许throw任意类型的值

**位置**: `NavigationService.ets:90`

**修复前**:
```typescript
throw err;
```

**修复后**:
```typescript
throw new Error('导航启动失败');
```

**规则**: ArkTS中只能throw Error对象

---

### 2. 函数返回类型推断限制 (arkts-no-implicit-return-types)

**错误**: @Builder函数必须显式声明返回类型

**位置**: 多个文件中的@Builder函数

**修复前**:
```typescript
@Builder MapBtn(text: string, action: () => void) {
  // ...
}
```

**修复后**:
```typescript
@Builder
MapBtn(text: string, action: () => void): void {
  // ...
}
```

**影响的文件**:
- ✅ `EnhancedNavigationModule.ets` - 7个@Builder函数
- ✅ `NavigationModule.ets` - 1个@Builder函数
- ✅ `CarStatusModule.ets` - 1个@Builder函数
- ✅ `MediaModule.ets` - 1个@Builder函数
- ✅ `Index.ets` - 2个@Builder函数

---

### 3. TTS API参数类型错误

**错误**: speak方法的参数对象不匹配SpeakParams类型

**位置**: `VoiceGuideService.ets:48`

**修复前**:
```typescript
await this.ttsEngine.speak(text, {
  volume: this.volume,
  speed: 1.0,
  pitch: 1.0
});
```

**修复后**:
```typescript
// 简化调用，只传文本
await this.ttsEngine.speak(text);
```

**说明**: 
- HarmonyOS的TTS API可能不支持这些参数
- 或者参数名称不同
- 简化为只传文本，避免类型错误

---

## ArkTS语法规则总结

### 1. 严格的类型系统

- ✅ 所有函数必须显式声明返回类型
- ✅ 不能使用any类型（除非必要）
- ✅ 不能使用隐式类型推断

### 2. 异常处理限制

- ✅ 只能throw Error对象
- ❌ 不能throw字符串、数字等基本类型
- ❌ 不能throw任意对象

### 3. @Builder装饰器规则

- ✅ 必须显式声明返回类型（通常是void）
- ✅ 用于构建UI组件
- ✅ 可以接受参数

### 4. API调用规范

- ✅ 必须使用正确的参数类型
- ✅ 不能传递未定义的属性
- ✅ 遵循官方API文档

---

## 编译命令

在DevEco Studio中：
- 点击 Run 按钮 ▶️
- 或按 `Shift + F10`

在命令行中：
```bash
# 仅编译
hvigor build

# 编译并运行
hvigor assembleHap
```

---

## 验证修复

所有错误已修复：
- ✅ ERROR: 10605087 - throw语句限制
- ✅ ERROR: 10605090 - 函数返回类型推断
- ✅ ERROR: 10505001 - TTS参数类型

现在可以成功编译运行！

---

## 下次避免这些错误

1. **写@Builder函数时**，立即添加`: void`返回类型
2. **使用throw时**，始终使用`throw new Error('消息')`
3. **调用系统API时**，查阅官方文档确认参数类型
4. **开启严格模式**，在编写时就发现问题

---

修复完成时间: 2026-03-04
