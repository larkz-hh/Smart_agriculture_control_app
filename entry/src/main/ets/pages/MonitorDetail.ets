import { promptAction } from '@kit.ArkUI';
import { GreenhouseModel } from '../model/GreenhouseModel';
import { IotService } from '../services/iot/IotService';
import { DatabaseManager } from '../data/DatabaseManager';
import window from '@ohos.window';
import { webview } from '@kit.ArkWeb';


@Component
struct HorizontalDataCard {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';
  @Prop colorCode: string = '';
  @Prop isSystemOnline: boolean = false;



  build() {
    Column() {
      Text(this.title).fontSize(14).fontColor('#666').margin({ bottom: 8 })
      Row({ space: 2 }) {
        Text(this.value).fontSize(26).fontWeight(FontWeight.Bold).fontColor(this.colorCode)
        Text(this.unit).fontSize(12).fontColor('#999').margin({ bottom: 4 })
      }.alignItems(VerticalAlign.Bottom)
    }
    .width(130)
    .height(80)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 4, color: '#05000000', offsetY: 2 })
    .opacity(this.isSystemOnline ? 1.0 : 0.4)
  }
}

@Component
struct DeviceControlItem {
  @Prop icon: string = '';
  @Prop name: string = '';
  @Prop isOn: boolean = false;
  @Prop isAuto: boolean = false;
  @Prop autoText: string = '';
  @Prop statusStr: string = '';
  @Prop isSystemOnline: boolean = false;
  onChangeCb: (val: boolean) => void = () => {};

  build() {
    Column() {
      Row() {
        Text(`${this.icon} ${this.name}`).fontSize(16).fontWeight(FontWeight.Medium)

        if (!this.isSystemOnline || this.statusStr === 'OFF') {
          Row({ space: 4 }) {
            Circle({ width: 6, height: 6 }).fill('#FF4D4F')
            Text('不在线').fontSize(12).fontColor('#FF4D4F')
          }.margin({ left: 8 })
        }

        Blank()

        if (this.isAuto) {
          Text('由系统自动托管').fontSize(12).fontColor('#00B96B').margin({ right: 10 })
        }
        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .selectedColor('#00B96B')
          .enabled(!this.isAuto && this.isSystemOnline && this.statusStr !== 'OFF')
          .onChange((val: boolean) => {
            this.onChangeCb(val);
          })
      }.width('100%')

      if (this.isAuto) {
        Row() {
          Text('自动触发规则:').fontSize(12).fontColor('#999')
          Text(this.autoText).fontSize(12).fontColor('#FF6B6B').margin({ left: 4 })
        }.width('100%').margin({ top: 8 })
      }
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ bottom: 10 })
  }
}

@CustomDialog
struct EditGreenhouseDialog {
  controller?: CustomDialogController
  @Link ghData: GreenhouseModel;
  confirmAction: () => void = () => {}

  build() {
    Column({ space: 15 }) {
      Text('编辑大棚信息').fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '大棚名称 (必填)', text: this.ghData.name })
        .onChange((val) => this.ghData.name = val)
      TextInput({ placeholder: '网关设备ID (必填)', text: this.ghData.deviceId })
        .onChange((val) => this.ghData.deviceId = val)
      TextInput({ placeholder: '种植作物 (可选)', text: this.ghData.crop })
        .onChange((val) => this.ghData.crop = val)


      TextInput({ placeholder: 'ESP32-CAM 流地址 (如 http://IP:81/stream)', text: this.ghData.camUrl || '' })
        .onChange((val) => this.ghData.camUrl = val)

      Row() {
        Text('生长阶段(选填)：').fontSize(14).fontColor('#666')
        Select([{value:'未设置'}, {value:'育苗'}, {value:'生长'}, {value:'开花'}, {value:'结果'}])
          .selected(this.ghData.stage === -1 ? 0 : this.ghData.stage + 1)
          .value(['未设置', '育苗', '生长', '开花', '结果'][this.ghData.stage === -1 ? 0 : this.ghData.stage + 1])
          .onSelect((index) => {
            this.ghData.stage = index - 1;
          })
      }.width('100%').justifyContent(FlexAlign.Start)

      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor('#EEE').fontColor('#666')
          .onClick(() => this.controller?.close())

        Button('保存').layoutWeight(1).backgroundColor('#00B96B')
          .onClick(() => {
            if (!this.ghData.name || this.ghData.name.trim() === '') {
              promptAction.showToast({ message: '请输入大棚名称！' });
              return;
            }
            if (!this.ghData.deviceId || this.ghData.deviceId.trim() === '') {
              promptAction.showToast({ message: '请输入网关设备ID' });
              return;
            }
            this.confirmAction();
            this.controller?.close();
          })
      }.margin({ top: 10 })

    }.padding(20).backgroundColor(Color.White).borderRadius(16)
  }
}

@Builder
export function MonitorDetailBuilder(_name: string, param: Object) {
  MonitorDetail({ ghData: param as GreenhouseModel })
}

@Component
export struct MonitorDetail {
  pathStack: NavPathStack = new NavPathStack();
  @State ghData: GreenhouseModel = new GreenhouseModel();
  @State editGhData: GreenhouseModel = new GreenhouseModel();
  controller: webview.WebviewController = new webview.WebviewController();

  @State isDrawerOpen: boolean = false;
  // 全屏状态标志
  @State isFullScreen: boolean = false;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: EditGreenhouseDialog({
      ghData: $editGhData,
      confirmAction: () => {
        this.ghData.name = this.editGhData.name;
        this.ghData.deviceId = this.editGhData.deviceId;
        this.ghData.crop = this.editGhData.crop;
        this.ghData.stage = this.editGhData.stage;
        this.ghData.camUrl = this.editGhData.camUrl; // 保存视频流地址

        DatabaseManager.updateGreenhouse(this.ghData).then(() => {
          promptAction.showToast({ message: '修改成功' });
          this.fetchShadowData();
        }).catch((err: Error) => {
          console.error("更新失败:", err.message);
        });
      }
    }),
    alignment: DialogAlignment.Center
  })

  @State airTemp: string = '0';
  @State airHum: string = '0';
  @State soilHum: string = '0';
  @State lightLux: string = '0';
  @State co2: string = '0';

  @State isSystemOnline: boolean = false;
  @State isAutoMode: boolean = false;

  @State pumpOpen: boolean = false;
  @State ledOpen: boolean = false;
  @State fanOpen: boolean = false;

  @State pumpStatusStr: string = 'OFF';
  @State fanStatusStr: string = 'OFF';
  @State ledStatusStr: string = 'OFF';

  @State thresholdSoil: number = 20;
  @State thresholdLight: number = 500;
  @State thresholdTemp: number = 32;
  @State thresholdHumi: number = 45;
  @State thresholdCO2: number = 1000;

  aboutToAppear() {
    this.fetchShadowData();
  }

  // 横竖屏切换
  async toggleFullScreen(isFull: boolean) {
    this.isFullScreen = isFull;
    try {
      let win = await window.getLastWindow(getContext(this));
      if (isFull) {
        // 强制横屏，并隐藏状态栏导航栏
        await win.setPreferredOrientation(window.Orientation.LANDSCAPE);
        await win.setWindowSystemBarEnable([]);
      } else {
        // 恢复竖屏，显示状态栏
        await win.setPreferredOrientation(window.Orientation.PORTRAIT);
        await win.setWindowSystemBarEnable(['status', 'navigation']);
      }
    } catch (err) {
      console.error('切换横竖屏失败', JSON.stringify(err));
    }
  }

  async fetchShadowData() {
    if (!this.ghData.deviceId) return;

    try {
      let res = await IotService.getDeviceShadow(this.ghData.deviceId);
      if (res.code === 200 && res.data) {
        this.isSystemOnline = true;
        this.airTemp = res.data.Temperature.toString();
        this.airHum = res.data.Humidity.toString();
        this.lightLux = res.data.Light.toString();
        this.soilHum = res.data.SoilMoisture.toString();
        this.co2 = res.data.CO2.toString();

        this.thresholdTemp = res.data.TempThreshold;
        this.thresholdHumi = res.data.HumiThreshold;
        this.thresholdLight = res.data.LightThreshold;
        this.thresholdSoil = res.data.SoilThreshold;
        this.thresholdCO2 = res.data.CO2Threshold;

        this.pumpStatusStr = res.data.PumpStatus;
        this.fanStatusStr = res.data.FanStatus;
        this.ledStatusStr = res.data.LedStatus;

        this.pumpOpen = res.data.PumpStatus === 'ON';
        this.fanOpen = res.data.FanStatus === 'ON';
        this.ledOpen = res.data.LedStatus === 'ON';

        this.isAutoMode = res.data.Mode === 'auto';
      } else {
        this.isSystemOnline = false;
        this.airTemp = '0';
        this.airHum = '0';
        this.soilHum = '0';
        this.lightLux = '0';
        this.co2 = '0';
        this.pumpStatusStr = 'OFF';
        this.fanStatusStr = 'OFF';
        this.ledStatusStr = 'OFF';
      }
    } catch (e) {
      console.error("请求异常：", JSON.stringify(e));
    }
  }

  //  提取出视频画面内容（复用）
  @Builder VideoContent() {
    if (this.ghData.camUrl) {
      // 填入视频流地址
      Web({ src: this.ghData.camUrl, controller: this.controller })
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        // 允许各种网页能力，保证视频流顺畅
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .mediaPlayGestureAccess(false) // 允许自动播放
    } else {
      // 没有视频流时显示默认图片
      Image($r('app.media.app_icon'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
  }

  build() {
    NavDestination() {

      Stack() {

        // ================== 主页面内容 ==================
        Scroll() {
          Column() {
            Row() {
              Column({ space: 4 }) {
                Text(this.ghData.name).fontSize(22).fontWeight(FontWeight.Bold)
                Row({ space: 8 }) {
                  Text(`作物: ${this.ghData.crop || '未设置'}`).fontSize(14).fontColor('#666')
                  if (this.ghData.stage !== undefined && this.ghData.stage >= 0) {
                    Text(['育苗期', '生长期', '开花期', '结果期'][this.ghData.stage])
                      .fontSize(12).fontColor('#00B96B').backgroundColor('#E6F8F0')
                      .padding({ left: 4, right: 4, top: 2, bottom: 2 }).borderRadius(4)
                  }
                }
              }.alignItems(HorizontalAlign.Start)
              Blank()

              Image($r('app.media.app_icon'))
                .width(24).height(24)
                .onClick(() => {
                  this.editGhData.id = this.ghData.id;
                  this.editGhData.name = this.ghData.name;
                  this.editGhData.deviceId = this.ghData.deviceId;
                  this.editGhData.crop = this.ghData.crop;
                  this.editGhData.stage = this.ghData.stage;
                  this.editGhData.camUrl = this.ghData.camUrl;
                  this.dialogController.open();
                })
            }.width('100%').padding(15)

            // 正常状态下的视频窗口
            Stack() {
              this.VideoContent()

              Row({ space: 6 }) {
                Circle({ width: 8, height: 8 }).fill('#FF4D4F')
                Text('LIVE 实时监控').fontSize(12).fontColor(Color.White)
              }.position({ x: 10, y: 10 }).backgroundColor('#66000000').padding(6).borderRadius(12)

              // 全屏按钮
              Row() {
                Text('[ 全屏放大 ]').fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Medium)
              }
              .position({ right: 10, bottom: 10 })
              .backgroundColor('rgba(0,0,0,0.6)')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(8)
              .onClick(() => {
                this.toggleFullScreen(true);
              })

            }.width('92%').height(200).backgroundColor('#000').borderRadius(16).clip(true)

            Text('环境数据监测').fontSize(16).fontWeight(FontWeight.Bold).width('100%').padding({ left: 15, top: 20, bottom: 10 })

            List({ space: 12 }) {
              ListItem() { HorizontalDataCard({ title: '空气温度', value: this.airTemp, unit: '℃', colorCode: '#FF6B6B', isSystemOnline: this.isSystemOnline }) }
              ListItem() { HorizontalDataCard({ title: '空气湿度', value: this.airHum, unit: '%', colorCode: '#4DABF7', isSystemOnline: this.isSystemOnline }) }
              ListItem() { HorizontalDataCard({ title: '土壤湿度', value: this.soilHum, unit: '', colorCode: '#8CE200', isSystemOnline: this.isSystemOnline }) }
              ListItem() { HorizontalDataCard({ title: '光照强度', value: this.lightLux, unit: 'Lx', colorCode: '#FCC419', isSystemOnline: this.isSystemOnline }) }
              ListItem() { HorizontalDataCard({ title: 'CO2浓度', value: this.co2, unit: 'ppm', colorCode: '#A9A9A9', isSystemOnline: this.isSystemOnline }) }
            }
            .listDirection(Axis.Horizontal).scrollBar(BarState.Off).width('100%').height(90).padding({ left: 15, right: 15 })

            Row() {
              Text('设备控制台').fontSize(16).fontWeight(FontWeight.Bold)
              Blank()
              Row({ space: 8 }) {
                Text(this.isAutoMode ? '自动接管' : '手动干预').fontSize(14).fontColor(this.isAutoMode ? '#00B96B' : '#FF6B6B')
                Toggle({ type: ToggleType.Switch, isOn: this.isAutoMode }).onChange((isOn) => this.isAutoMode = isOn)
              }
            }.width('100%').padding({ left: 15, right: 15, top: 25, bottom: 10 })

            Column() {
              DeviceControlItem({
                icon: '💦', name: '滴灌水泵', isOn: this.pumpOpen, isAuto: this.isAutoMode,
                autoText: `当土壤或空气湿度低于设定值时启动`, statusStr: this.pumpStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => { this.pumpOpen = val }
              })
              DeviceControlItem({
                icon: '☀️', name: 'LED补光灯', isOn: this.ledOpen, isAuto: this.isAutoMode,
                autoText: `当光照强度低于 ${this.thresholdLight}Lx 时启动`, statusStr: this.ledStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => { this.ledOpen = val }
              })
              DeviceControlItem({
                icon: '💨', name: '通风排气扇', isOn: this.fanOpen, isAuto: this.isAutoMode,
                autoText: `当温度或CO2浓度高于设定值时启动`, statusStr: this.fanStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => { this.fanOpen = val }
              })
            }.padding({ left: 15, right: 15, bottom: 40 })

          }.width('100%')
        }
        .width('100%').height('100%').backgroundColor('#F5F7FA')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        // ================== 右侧抽屉标签 ==================
        if (this.isAutoMode && !this.isDrawerOpen && !this.isFullScreen) {
          Row() { Text('< 设置阈值').fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Bold) }
          .backgroundColor('#00B96B').padding({ left: 12, right: 8, top: 12, bottom: 12 }).borderRadius({ topLeft: 20, bottomLeft: 20 })
          .position({ right: 0, top: '45%' }).shadow({ radius: 6, color: '#4400B96B', offsetX: -2, offsetY: 2 })
          .onClick(() => { animateTo({ duration: 350, curve: Curve.FastOutSlowIn }, () => { this.isDrawerOpen = true; }) })
        }

        // ================== 侧边抽屉面板 ==================
        if (this.isDrawerOpen && !this.isFullScreen) {
          Row().width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .onClick(() => { animateTo({ duration: 300, curve: Curve.EaseIn }, () => { this.isDrawerOpen = false; }) }).zIndex(10)

          Column() {
            Row() {
              Text('自动触发阈值').fontSize(20).fontWeight(FontWeight.Bold)
              Blank()
              Text('完成').fontColor('#00B96B').fontSize(16).fontWeight(FontWeight.Medium)
                .onClick(() => { animateTo({ duration: 300, curve: Curve.EaseIn }, () => { this.isDrawerOpen = false; }) })
            }.width('100%').padding({ top: 50, bottom: 20, left: 20, right: 20 })

            Scroll() {
              Column({ space: 15 }) {
                Column() { Row() { Text('🌱 土壤湿度下限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdSoil}`).fontColor('#00B96B').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdSoil, min: 0, max: 4095 }).selectedColor('#00B96B').onChange((v) => this.thresholdSoil = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('💧 空气湿度下限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdHumi}%`).fontColor('#4DABF7').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdHumi, min: 0, max: 100 }).selectedColor('#4DABF7').onChange((v) => this.thresholdHumi = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('☀️ 光照强度下限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdLight}Lx`).fontColor('#FCC419').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdLight, min: 0, max: 2000 }).selectedColor('#FCC419').onChange((v) => this.thresholdLight = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('🌡️ 空气温度上限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdTemp}℃`).fontColor('#FF6B6B').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdTemp, min: 0, max: 50 }).selectedColor('#FF6B6B').onChange((v) => this.thresholdTemp = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('💨 CO2浓度上限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdCO2}ppm`).fontColor('#A9A9A9').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdCO2, min: 0, max: 5000 }).selectedColor('#A9A9A9').onChange((v) => this.thresholdCO2 = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
              }.width('100%').padding({ left: 15, right: 15, bottom: 40 })
            }.scrollBar(BarState.Off).layoutWeight(1)
          }
          .width('85%').height('100%').backgroundColor('#F5F7FA').expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .position({ right: 0, top: 0 }).transition(TransitionEffect.move(TransitionEdge.END)).zIndex(11)
        }

        // ================== 横向全屏视频覆盖层 ==================
        if (this.isFullScreen) {
          Stack() {
            // 背景黑底，画面等比例居中
            this.VideoContent()

            // 退出全屏按钮 (左上角)
            Row({ space: 6 }) {
              Text('< 返回').fontSize(16).fontColor(Color.White).fontWeight(FontWeight.Bold)
            }
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .backgroundColor('rgba(0,0,0,0.5)')
            .borderRadius(8)
            .position({ x: 20, y: 20 })
            .onClick(() => {
              this.toggleFullScreen(false);
            })

          }
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 充满整个屏幕
          .zIndex(999) // 覆盖
        }

      }.width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .onReady((ctx) => {
      this.pathStack = ctx.pathStack;
    })
    // 监听返回键事件
    .onBackPressed(() => {
      if (this.isFullScreen) {
        this.toggleFullScreen(false);
        return true; // 拦截默认返回
      }
      return false; // 正常返回上一页
    })
  }
}