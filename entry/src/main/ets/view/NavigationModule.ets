import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

@Component
export struct NavigationModule {
  @State isMapLoaded: boolean = false;
  @State isNightMode: boolean = true;
  @State hasLocationPermission: boolean = false;
  @State latitude: number = 39.9042;
  @State longitude: number = 116.4074;
  @State altitude: number = 0;
  @State speed: number = 0;
  @State accuracy: number = 0;
  @State userHeading: number = 0;
  @State addressText: string = "等待GPS信号...";
  @State zoomLevel: number = 15;
  private mapController: map.MapComponentController | null = null;
  private locationCallback: (location: geoLocationManager.Location) => void = (location) => { this.updateLocationState(location); };

  aboutToAppear() { this.reqPermissionsFromUser(); }
  aboutToDisappear() { try { geoLocationManager.off('locationChange', this.locationCallback); } catch (err) {} }

  async reqPermissionsFromUser() {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const data = await atManager.requestPermissionsFromUser(context, ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION']);
      if (data.authResults[0] === 0) {
        this.hasLocationPermission = true;
        if (this.mapController) this.startRealLocation();
      }
    } catch (err) {}
  }

  async startRealLocation() {
    if (!this.mapController || !this.hasLocationPermission) return;
    try {
      this.mapController.setMyLocationEnabled(true);
      this.mapController.setZoomControlsEnabled(true);
      this.mapController.setMyLocationControlsEnabled(true);
      let req: geoLocationManager.LocationRequest = { priority: 0x203, scenario: 0x301, timeInterval: 1, distanceInterval: 0, maxAccuracy: 0 };
      geoLocationManager.on('locationChange', req, this.locationCallback);
      this.addressText = "定位中...";
    } catch (err) {}
  }

  updateLocationState(location: geoLocationManager.Location) {
    this.latitude = location.latitude;
    this.longitude = location.longitude;
    this.speed = location.speed;
    this.userHeading = location.direction;
    this.addressText = "实时巡航";
  }

  onMapLoad(controller: map.MapComponentController) {
    this.mapController = controller;
    this.isMapLoaded = true;
    try {
      // 底部留出 150vp 的 Padding，让 MapKit 自带的 Logo 和 Zoom 按钮上移
      // 这样自带的缩放按钮就会跑到信息面板上方，不会被挡住
      this.mapController.setPadding({ top: 0, left: 0, right: 0, bottom: 150 });
    } catch(e) {}
    if (this.hasLocationPermission) this.startRealLocation();
    this.updateMapStyle();
  }

  updateMapStyle() {
    if (!this.mapController) return;
    try { this.mapController.setDayNightMode(this.isNightMode ? mapCommon.DayNightMode.NIGHT : mapCommon.DayNightMode.DAY); } catch (e) {}
  }

  // 手动缩放
  changeZoom(delta: number): void {
    if (!this.mapController) return;
    this.zoomLevel = Math.max(3, Math.min(20, this.zoomLevel + delta));
    try {
      let cameraUpdate = map.newCameraPosition({
        target: { latitude: this.latitude, longitude: this.longitude },
        zoom: this.zoomLevel, tilt: 45, bearing: this.userHeading
      });
      this.mapController.animateCamera(cameraUpdate);
    } catch(e) {}
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) { // 对齐到底部中间

      // 1. 地图层 (全屏)
      Stack() {
        MapComponent({
          mapOptions: { position: { target: { latitude: 39.9, longitude: 116.4 }, zoom: 15 }, mapType: mapCommon.MapType.STANDARD },
          mapCallback: (err, controller) => { if (!err && controller) this.onMapLoad(controller); }
        })
          .width('100%').height('100%')
      }

      // 2. 右侧控制按钮 (靠右，避开左边)
      Column({ space: 15 }) {
        this.MapBtn(this.isNightMode ? "☀️" : "🌙", () => {
          this.isNightMode = !this.isNightMode;
          this.updateMapStyle();
        })
        this.MapBtn("＋", () => this.changeZoom(1))
        this.MapBtn("－", () => this.changeZoom(-1))
        this.MapBtn("◎", () => {
          if(this.hasLocationPermission && this.mapController) {
            try {
              this.mapController.animateCamera(map.newCameraPosition({
                target: { latitude: this.latitude, longitude: this.longitude },
                zoom: this.zoomLevel, tilt: 45, bearing: this.userHeading
              }));
            } catch(e) {}
          }
        })
      }
      .alignItems(HorizontalAlign.End)
      .position({ x: '100%', y: '40%' }) // 放在右侧中间
      .markAnchor({ x: '100%', y: '50%' })
      .padding({ right: 20 })

      // 3. 底部信息面板 (居中悬浮)
      // 位于底部中间，左下角的菜单按钮在它左边，互不干扰
      Row() {
        Column() {
          Text(`${(this.speed * 3.6).toFixed(0)}`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#00E5FF')
          Text("km/h").fontSize(12).fontColor('rgba(255,255,255,0.6)')
        }.margin({ right: 20 })

        Divider().vertical(true).height(30).color('rgba(255,255,255,0.2)')

        Column() {
          Text(this.addressText).fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Medium)
          Text(`Lat: ${this.latitude.toFixed(4)}  Lng: ${this.longitude.toFixed(4)}`).fontSize(12).fontColor('rgba(255,255,255,0.6)').margin({ top: 4 })
        }.alignItems(HorizontalAlign.Start).margin({ left: 20 })
      }
      .padding({ left: 30, right: 30, top: 16, bottom: 16 })
      .backgroundColor('rgba(15, 23, 42, 0.9)')
      .backdropBlur(30)
      .borderRadius(24)
      .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
      .shadow({ radius: 30, color: 'rgba(0,0,0,0.5)', offsetY: 10 })
      .margin({ bottom: 40 }) // 底部留空
    }
  }

  @Builder
  MapBtn(text: string, action: () => void): void {
    Button(text)
      .type(ButtonType.Circle).width(50).height(50)
      .fontSize(20).fontColor(Color.White)
      .backgroundColor('rgba(30, 41, 59, 0.9)')
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)' })
      .onClick(action)
  }
}