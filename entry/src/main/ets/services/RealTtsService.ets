import { textToSpeech } from '@kit.CoreSpeechKit'
import { BusinessError } from '@kit.BasicServicesKit'

export class RealTtsService {
  private static instance: RealTtsService | null = null
  private engine: textToSpeech.TextToSpeechEngine | null = null
  private initializing: boolean = false
  private utteranceId: number = 1

  static getInstance(): RealTtsService {
    if (!RealTtsService.instance) {
      RealTtsService.instance = new RealTtsService()
    }
    return RealTtsService.instance
  }

  async ensureEngine(): Promise<boolean> {
    if (this.engine) return true
    if (this.initializing) return false
    this.initializing = true
    try {
      const params: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 1
      }
      this.engine = await textToSpeech.createEngine(params)
      console.info('[RealTts] engine ready')
      return true
    } catch (e) {
      const err = e as BusinessError
      console.error(`[RealTts] init fail code=${err.code} msg=${err.message}`)
      this.engine = null
      return false
    } finally {
      this.initializing = false
    }
  }

  async speak(text: string): Promise<boolean> {
    if (text === '') return false
    const ok = await this.ensureEngine()
    if (!ok || !this.engine) return false
    try {
      const id = (this.utteranceId++).toString()
      const params: textToSpeech.SpeakParams = {
        requestId: id,
        extraParams: { speed: 1, volume: 1, pitch: 1, languageContext: 'zh-CN', audioType: 'pcm', queueMode: 0 }
      }
      this.engine.speak(text, params)
      console.info(`[RealTts] speaking id=${id} text=${text.substring(0, 20)}...`)
      return true
    } catch (e) {
      const err = e as BusinessError
      console.error(`[RealTts] speak fail code=${err.code} msg=${err.message}`)
      return false
    }
  }

  async stop(): Promise<void> {
    if (!this.engine) return
    try {
      this.engine.stop()
    } catch (_) {
    }
  }

  async release(): Promise<void> {
    if (this.engine) {
      try {
        this.engine.shutdown()
      } catch (_) {
      }
      this.engine = null
    }
  }
}
