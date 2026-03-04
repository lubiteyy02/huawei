# 🎯 ArkTS语法快速参考

## 常见编译错误及解决方案

### 1. @Builder函数必须有返回类型

❌ **错误写法**:
```typescript
@Builder MyComponent() {
  Text('Hello')
}
```

✅ **正确写法**:
```typescript
@Builder
MyComponent(): void {
  Text('Hello')
}
```

---

### 2. 箭头函数必须有类型注解

❌ **错误写法**:
```typescript
Button('点击')
  .onClick(() => {
    console.log('clicked');
  })

TextInput()
  .onChange((value) => {
    this.text = value;
  })
```

✅ **正确写法**:
```typescript
Button('点击')
  .onClick((): void => {
    console.log('clicked');
  })

TextInput()
  .onChange((value: string): void => {
    this.text = value;
  })
```

---

### 3. throw只能抛出Error对象

❌ **错误写法**:
```typescript
throw 'error message';
throw err;  // err可能不是Error类型
throw { code: 500, message: 'error' };
```

✅ **正确写法**:
```typescript
throw new Error('error message');
throw new Error(err.message || '未知错误');
```

---

### 4. 函数必须显式声明返回类型

❌ **错误写法**:
```typescript
function calculate(a: number, b: number) {
  return a + b;
}

async getData() {
  return await fetch();
}
```

✅ **正确写法**:
```typescript
function calculate(a: number, b: number): number {
  return a + b;
}

async getData(): Promise<Data> {
  return await fetch();
}
```

---

### 5. API调用必须使用正确的参数

❌ **错误写法**:
```typescript
// TTS API
ttsEngine.speak(text);  // 缺少回调参数

// HTTP请求
http.request(url);  // 缺少options参数
```

✅ **正确写法**:
```typescript
// TTS API - 需要回调
ttsEngine.speak(text, (err) => {
  if (err) console.error(err);
});

// HTTP请求 - 需要options
http.request(url, {
  method: http.RequestMethod.GET
}, callback);
```

---

## ArkTS vs TypeScript 主要区别

| 特性 | TypeScript | ArkTS |
|------|-----------|-------|
| 类型推断 | ✅ 支持 | ⚠️ 受限 |
| any类型 | ✅ 允许 | ❌ 不推荐 |
| throw任意值 | ✅ 允许 | ❌ 只能Error |
| 隐式返回类型 | ✅ 允许 | ❌ 必须显式 |
| 动态属性 | ✅ 允许 | ❌ 受限 |

---

## 最佳实践

### 1. 始终显式声明类型

```typescript
// 变量
let count: number = 0;
let name: string = 'test';
let isActive: boolean = true;

// 函数参数和返回值
function add(a: number, b: number): number {
  return a + b;
}

// 箭头函数
const multiply = (a: number, b: number): number => a * b;
```

### 2. 使用接口定义数据结构

```typescript
interface User {
  id: number;
  name: string;
  email: string;
}

function getUser(): User {
  return {
    id: 1,
    name: 'test',
    email: 'test@example.com'
  };
}
```

### 3. 正确处理异步操作

```typescript
async function fetchData(): Promise<Data> {
  try {
    const response = await http.request(url, options);
    return JSON.parse(response.result as string);
  } catch (err) {
    throw new Error('请求失败');
  }
}
```

### 4. @Builder组件规范

```typescript
@Component
export struct MyComponent {
  @State text: string = '';
  
  // Builder必须有返回类型
  @Builder
  CustomButton(label: string, action: () => void): void {
    Button(label)
      .onClick(action)
  }
  
  build() {
    Column() {
      // 使用Builder
      this.CustomButton('点击', (): void => {
        this.text = 'clicked';
      })
    }
  }
}
```

---

## 常用类型定义

### 事件回调类型

```typescript
// 点击事件
.onClick((): void => { })

// 输入变化
.onChange((value: string): void => { })

// 提交事件
.onSubmit((): void => { })

// 滑动变化
.onChange((value: number, mode: SliderChangeMode): void => { })
```

### Promise类型

```typescript
// 无返回值
async function doSomething(): Promise<void> { }

// 有返回值
async function getData(): Promise<Data> { }

// 可能失败
async function tryFetch(): Promise<Data | null> { }
```

---

## 调试技巧

### 1. 查看编译错误

```bash
# 在DevEco Studio中
# 查看底部的 Build 面板
# 点击错误可以跳转到对应代码

# 命令行编译
hvigor build
```

### 2. 常见错误代码

- `10605087` - throw语句限制
- `10605090` - 函数返回类型推断限制
- `10505001` - 参数类型不匹配
- `10505002` - 属性不存在

### 3. 快速修复

在DevEco Studio中：
1. 将光标放在错误处
2. 按 `Alt + Enter`
3. 选择快速修复选项

---

## 参考资源

- [ArkTS语法规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-get-started-V5)
- [ArkUI组件参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/arkui-ts-components-V5)
- [常见问题FAQ](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs-V5/faqs-arkts-V5)

---

**记住**: ArkTS比TypeScript更严格，但这能帮助你写出更安全、更高性能的代码！💪
