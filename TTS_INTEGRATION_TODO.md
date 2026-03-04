# 🔊 TTS语音播报集成待办

## 当前状态

VoiceGuideService已创建，但TTS功能暂时使用console.log模拟，需要后续集成真实的TTS SDK。

## 为什么暂时注释？

1. **API文档不完整** - CoreSpeechKit的具体API用法需要查阅官方文档
2. **避免编译错误** - 确保项目能先运行起来
3. **功能优先级** - 先实现核心导航功能，语音播报可以后续添加

## 集成步骤

### 1. 查阅官方文档

访问华为开发者文档：
- https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/text-to-speech-V5
- 查找 `@kit.CoreSpeechKit` 的使用方法
- 确认 `textToSpeech` API的正确调用方式

### 2. 申请权限

在 `entry/src/main/module.json5` 中添加：

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.MICROPHONE",
        "reason": "$string:microphone_reason"
      }
    ]
  }
}
```

### 3. 集成TTS SDK

根据官方文档，可能的实现方式：

```typescript
import { textToSpeech } from '@kit.CoreSpeechKit';

// 方式1：使用createEngine
const engine = await textToSpeech.createEngine({
  language: 'zh-CN',
  // 其他配置...
});

// 方式2：直接调用speak
textToSpeech.speak({
  text: '播报内容',
  language: 'zh-CN',
  // 其他参数...
});
```

### 4. 测试TTS功能

```typescript
// 简单测试
async testTTS() {
  try {
    await this.voiceService.speak('测试语音播报');
    console.log('TTS测试成功');
  } catch (err) {
    console.error('TTS测试失败:', err);
  }
}
```

## 当前实现

### VoiceGuideService.ets

```typescript
// 暂时使用console.log模拟
async speak(text: string): Promise<void> {
  console.log('[TTS] 播报:', text);
  // TODO: 集成真实的TTS引擎
}
```

### 功能列表

- ✅ speakNavigation() - 导航指令播报
- ✅ speakArrival() - 到达提醒
- ✅ speakDeviation() - 偏航提醒
- ✅ setEnabled() - 启用/禁用
- ✅ setVolume() - 音量控制

## 替代方案

如果官方TTS不可用，可以考虑：

### 1. 使用第三方TTS服务

- 百度语音合成
- 讯飞语音
- 阿里云TTS

### 2. 使用Web API

```typescript
// 使用浏览器的Web Speech API（如果支持）
const utterance = new SpeechSynthesisUtterance(text);
utterance.lang = 'zh-CN';
speechSynthesis.speak(utterance);
```

### 3. 预录音频

- 录制常用导航指令
- 存储为音频文件
- 使用AudioPlayer播放

## 优先级

- 🔴 高优先级：核心导航功能（定位、路径规划）
- 🟡 中优先级：地图SDK集成、POI搜索
- 🟢 低优先级：语音播报（可选功能）

## 建议

1. **先完成核心功能** - 确保地图和导航能正常工作
2. **后续添加TTS** - 作为增强功能
3. **提供开关选项** - 让用户可以关闭语音

## 参考资料

- [HarmonyOS语音服务开发指南](https://developer.huawei.com/consumer/cn/doc/)
- [ArkTS API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/)
- [语音合成最佳实践](https://developer.huawei.com/consumer/cn/doc/)

---

**注意**: 当前版本的VoiceGuideService可以正常编译运行，只是语音功能暂时用日志代替。
