import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

@Component
export struct NavigationModule {
  @State isMapLoaded: boolean = false;
  @State isNightMode: boolean = true;
  @State hasLocationPermission: boolean = false;

  // 实时定位数据
  @State latitude: number = 39.9042;
  @State longitude: number = 116.4074;
  @State altitude: number = 0;
  @State speed: number = 0;
  @State accuracy: number = 0;
  @State userHeading: number = 0;
  @State addressText: string = "等待GPS信号...";

  private mapController: map.MapComponentController | null = null;

  private locationCallback: (location: geoLocationManager.Location) => void = (location: geoLocationManager.Location): void => {
    this.updateLocationState(location);
  };

  aboutToAppear(): void {
    this.reqPermissionsFromUser();
  }

  aboutToDisappear(): void {
    try {
      geoLocationManager.off('locationChange', this.locationCallback);
    } catch (err) {
      console.error("Stop location listener failed:", err);
    }
  }

  async reqPermissionsFromUser(): Promise<void> {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      const permissions: Array<Permissions> = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const data = await atManager.requestPermissionsFromUser(context, permissions);
      if (data.authResults.length > 0 && data.authResults[0] === 0) {
        this.hasLocationPermission = true;
        if (this.mapController) {
          this.startRealLocation();
        }
      }
    } catch (err) {
      console.error("Permission request failed:", err);
    }
  }

  async startRealLocation(): Promise<void> {
    if (!this.mapController || !this.hasLocationPermission) return;

    try {
      this.mapController.setMyLocationEnabled(true);
      // 开启自带缩放控件
      this.mapController.setZoomControlsEnabled(true);
      this.mapController.setMyLocationControlsEnabled(true);

      let requestInfo: geoLocationManager.LocationRequest = {
        'priority': geoLocationManager.LocationRequestPriority.ACCURACY,
        'scenario': geoLocationManager.LocationRequestScenario.NAVIGATION,
        'timeInterval': 1,
        'distanceInterval': 0,
        'maxAccuracy': 0
      };

      geoLocationManager.on('locationChange', requestInfo, this.locationCallback);
      this.addressText = "正在获取卫星信号...";

    } catch (err) {
      console.error("Start real location failed:", err);
      this.addressText = "定位服务异常";
    }
  }

  updateLocationState(location: geoLocationManager.Location): void {
    this.latitude = location.latitude;
    this.longitude = location.longitude;
    this.altitude = location.altitude;
    this.speed = location.speed;
    this.accuracy = location.accuracy;
    this.userHeading = location.direction;
    this.addressText = "实时巡航模式";

    if (this.mapController) {
      try {
        let cameraUpdate: map.CameraUpdate = map.newCameraPosition({
          target: {
            latitude: this.latitude,
            longitude: this.longitude
          },
          zoom: 18,
          tilt: 45,
          bearing: this.userHeading
        });
        this.mapController.animateCamera(cameraUpdate);
      } catch (e) {}
    }
  }

  onMapLoad(controller: map.MapComponentController): void {
    this.mapController = controller;
    this.isMapLoaded = true;

    // 关键：设置底部 Padding，把 Logo 和 缩放按钮 顶上去，避开底部仪表盘
    try {
      this.mapController.setPadding({ top: 0, left: 0, right: 0, bottom: 250 });
    } catch(e) {
      console.error("Set padding failed:", e);
    }

    if (this.hasLocationPermission) {
      this.startRealLocation();
    }
    this.updateMapStyle();
  }

  updateMapStyle(): void {
    if (!this.mapController) return;
    try {
      this.mapController.setDayNightMode(
        this.isNightMode ? mapCommon.DayNightMode.NIGHT : mapCommon.DayNightMode.DAY
      );
    } catch (e) {}
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 1. 地图
      Stack() {
        MapComponent({
          mapOptions: {
            position: { target: { latitude: 39.9, longitude: 116.4 }, zoom: 15 },
            mapType: mapCommon.MapType.STANDARD
          },
          mapCallback: (err, controller) => {
            if (!err && controller) {
              this.onMapLoad(controller);
            }
          }
        })
          .width('100%').height('100%')
      }
      .width('100%').height('100%')

      // 2. 自定义控制按钮 (夜间模式)
      Column({ space: 15 }) {
        Button(this.isNightMode ? "☀️" : "🌙")
          .type(ButtonType.Circle)
          .width(50).height(50)
          .fontSize(20)
          .fontColor(Color.White)
          .backgroundColor('rgba(30, 41, 59, 0.9)')
          .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)' })
          .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
          .onClick(() => {
            this.isNightMode = !this.isNightMode;
            this.updateMapStyle();
          })
      }
      .width(60)
      .alignItems(HorizontalAlign.Center)
      .position({ x: 20, y: 60 })

      // 3. 底部仪表盘
      Column() {
        Row() {
          Text((this.speed * 3.6).toFixed(0))
            .fontSize(60)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00E5FF')
          Text("km/h")
            .fontSize(16)
            .fontColor('#00E5FF')
            .margin({ top: 20, left: 5 })
        }

        Divider().color('rgba(255,255,255,0.2)').margin({ top: 10, bottom: 10 })

        Column() {
          this.DataRow("状态", this.addressText)
          this.DataRow("纬度", this.latitude.toFixed(5))
          this.DataRow("经度", this.longitude.toFixed(5))
          this.DataRow("海拔", `${this.altitude.toFixed(1)} m`)
          this.DataRow("航向", `${this.userHeading.toFixed(0)}°`)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }
      .width('70%')
      .padding(20)
      .margin({ bottom: 40, right: 20 }) // 适配隐藏式Dock
      .borderRadius(24)
      .backgroundColor('rgba(15, 23, 42, 0.9)')
      .backdropBlur(20)
      .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
      .shadow({ radius: 30, color: 'rgba(0,0,0,0.5)', offsetY: 10 })
    }
  }

  @Builder DataRow(label: string, value: string): void {
    Row() {
      Text(label).fontSize(14).fontColor('#94A3B8').width(50)
      Text(value).fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Medium)
    }.margin({ top: 4 })
  }
}