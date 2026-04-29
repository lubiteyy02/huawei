import router from '@ohos.router'

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
  private readonly musicItems: MusicItem[] = [
    { id: 1, title: '七里香', artist: '周杰伦', progress: 64, device: '手机正在播放' },
    { id: 2, title: '稻香', artist: '周杰伦', progress: 22, device: '车机可续接' },
    { id: 3, title: '晴天', artist: '周杰伦', progress: 89, device: '最近播放' }
  ];

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
