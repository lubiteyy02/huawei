import router from '@ohos.router'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'
import { MusicStateSnapshot } from '../services/CollaborationApiService'

interface MusicItem {
  id: number;
  title: string;
  artist: string;
  progress: number;
  device: string;
}

@Entry
@Component
struct CollaborationMusicPage {
  @State private musicItems: MusicItem[] = [];
  @State private nowPlaying: MusicStateSnapshot | null = null;
  @State private resumeHint: string = '';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'music.stateChanged') {
      void this.refreshNowPlaying();
      void this.refreshMusic();
    } else if (event.type === 'overview.refreshed') {
      void this.refreshMusic();
    }
  };

  aboutToAppear() {
    void this.refreshMusic();
    void this.refreshNowPlaying();
    this.viewModel.onSyncEvent(this.syncListener);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
  }

  private async refreshMusic(): Promise<void> {
    this.musicItems = await this.viewModel.loadMusic() as MusicItem[];
  }

  private async refreshNowPlaying(): Promise<void> {
    const state = await this.viewModel.loadMusicState();
    this.nowPlaying = state;
  }

  private formatPosition(ms: number): string {
    const total = Math.max(0, Math.floor(ms / 1000));
    const m = Math.floor(total / 60).toString().padStart(2, '0');
    const s = (total % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  private async resumeOnCar(): Promise<void> {
    if (!this.nowPlaying) {
      return;
    }
    const ok = await this.viewModel.syncMusic(this.nowPlaying.songId, true, this.nowPlaying.position);
    this.resumeHint = ok ? `已在车机续接：${this.nowPlaying.title} @ ${this.formatPosition(this.nowPlaying.position)}` : '续接失败，请稍后重试';
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .fontSize(12)
          .backgroundColor('rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => router.back())
        Text('音乐同步')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(18)

      Scroll() {
        Column({ space: 12 }) {
          if (this.nowPlaying !== null && this.nowPlaying!.songId > 0) {
            Column({ space: 8 }) {
              Row() {
                Text('当前手机播放').fontSize(11).fontColor('rgba(255,255,255,0.55)')
                Blank()
                Text(this.nowPlaying!.playing ? '播放中' : '已暂停')
                  .fontSize(10)
                  .fontColor(this.nowPlaying!.playing ? '#22C55E' : 'rgba(255,255,255,0.6)')
              }
              .width('100%')
              Text(this.nowPlaying!.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text(`${this.nowPlaying!.artist} · ${this.formatPosition(this.nowPlaying!.position)}`)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
              Row() {
                Button('续接到车机')
                  .fontSize(12)
                  .backgroundColor('#8B5CF6')
                  .fontColor('#FFFFFF')
                  .borderRadius(14)
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .onClick(() => { void this.resumeOnCar(); })
                Blank()
                if (this.resumeHint !== '') {
                  Text(this.resumeHint).fontSize(10).fontColor('#A78BFA').maxLines(2)
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('rgba(139,92,246,0.14)')
            .borderRadius(18)
            .border({ width: 1, color: 'rgba(139,92,246,0.28)' })
          }
          ForEach(this.musicItems, (music: MusicItem) => {
            Column({ space: 6 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(music.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text(music.artist).fontSize(11).fontColor('rgba(255,255,255,0.6)')
                }
                .layoutWeight(1)
                Text(music.device).fontSize(10).fontColor('#A78BFA')
              }
              Progress({ value: music.progress, total: 100, style: ProgressStyle.Linear })
                .color('#8B5CF6')
                .backgroundColor('rgba(255,255,255,0.08)')
            }
            .width('100%')
            .padding(14)
            .backgroundColor('rgba(255,255,255,0.06)')
            .borderRadius(18)
          })
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
