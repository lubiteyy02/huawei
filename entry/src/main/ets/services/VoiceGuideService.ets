/**
 * 语音播报服务
 */
import { textToSpeech } from '@kit.CoreSpeechKit';

export class VoiceGuideService {
  private static instance: VoiceGuideService;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private isEnabled: boolean = true;
  private volume: number = 0.8;
  
  private constructor() {
    this.initTTS();
  }
  
  static getInstance(): VoiceGuideService {
    if (!VoiceGuideService.instance) {
      VoiceGuideService.instance = new VoiceGuideService();
    }
    return VoiceGuideService.instance;
  }
  
  /**
   * 初始化TTS引擎
   */
  private async initTTS(): Promise<void> {
    try {
      this.ttsEngine = await textToSpeech.createEngine({
        language: 'zh-CN',
        person: 0,  // 发音人
        online: 1   // 在线引擎
      });
    } catch (err) {
      console.error('Init TTS error:', err);
    }
  }
  
  /**
   * 播报文本
   */
  async speak(text: string): Promise<void> {
    if (!this.isEnabled || !this.ttsEngine) {
      return;
    }
    
    try {
      await this.ttsEngine.speak(text, {
        volume: this.volume,
        speed: 1.0,
        pitch: 1.0
      });
    } catch (err) {
      console.error('Speak error:', err);
    }
  }
  
  /**
   * 停止播报
   */
  stop(): void {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.stop();
      } catch (err) {
        console.error('Stop TTS error:', err);
      }
    }
  }
  
  /**
   * 设置是否启用语音
   */
  setEnabled(enabled: boolean): void {
    this.isEnabled = enabled;
  }
  
  /**
   * 设置音量
   */
  setVolume(volume: number): void {
    this.volume = Math.max(0, Math.min(1, volume));
  }
  
  /**
   * 播报导航指令
   */
  async speakNavigation(instruction: string, distance: number): Promise<void> {
    let text = '';
    
    if (distance > 1000) {
      text = `前方${Math.round(distance / 100) / 10}公里，${instruction}`;
    } else if (distance > 500) {
      text = `前方${Math.round(distance / 100) * 100}米，${instruction}`;
    } else if (distance > 200) {
      text = `前方${Math.round(distance / 10) * 10}米，${instruction}`;
    } else {
      text = instruction;
    }
    
    await this.speak(text);
  }
  
  /**
   * 播报到达提醒
   */
  async speakArrival(): Promise<void> {
    await this.speak('您已到达目的地');
  }
  
  /**
   * 播报偏航提醒
   */
  async speakDeviation(): Promise<void> {
    await this.speak('您已偏离路线，正在重新规划');
  }
  
  /**
   * 释放资源
   */
  release(): void {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.shutdown();
      } catch (err) {
        console.error('Release TTS error:', err);
      }
      this.ttsEngine = null;
    }
  }
}
