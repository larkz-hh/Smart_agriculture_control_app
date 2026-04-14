import { promptAction } from '@kit.ArkUI';
import { GreenhouseModel } from '../model/GreenhouseModel';
import { IotService } from '../services/iot/IotService';
import { DatabaseManager } from '../data/DatabaseManager';
import window from '@ohos.window';
import { webview } from '@kit.ArkWeb';
import { AiService } from '../services/ai/AIService';

export class CmdStage { Stage: string = '0'; }
export class CmdMode { Mode: string = ''; }
export class CmdPump { Pump: string = ''; }
export class CmdLed { Led: string = ''; }
export class CmdFan { Fan: string = ''; }
export class CmdHumidifier { Humidifier: string = ''; }
export class CmdThreshold {
  temp: number = 0;
  humi: number = 0;
  light: number = 0;
  soil: number = 0;
  co2: number = 0;
}

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
        if (!this.isSystemOnline) {
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
          .enabled(!this.isAuto)
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

@Preview
@Component
export struct MonitorDetail {
  pathStack: NavPathStack = new NavPathStack();
  @State ghData: GreenhouseModel = new GreenhouseModel();
  @State editGhData: GreenhouseModel = new GreenhouseModel();
  controller: webview.WebviewController = new webview.WebviewController();
  fsController: webview.WebviewController = new webview.WebviewController();

  @State isDrawerOpen: boolean = false;
  @State isFullScreen: boolean = false;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: EditGreenhouseDialog({
      ghData: $editGhData,
      confirmAction: () => {
        let isStageChanged = (this.ghData.stage !== this.editGhData.stage);

        this.ghData.name = this.editGhData.name;
        this.ghData.deviceId = this.editGhData.deviceId;
        this.ghData.crop = this.editGhData.crop;
        this.ghData.stage = this.editGhData.stage;
        this.ghData.camUrl = this.editGhData.camUrl;

        if (isStageChanged && this.ghData.stage >= 0) {
          let stageCmd = new CmdStage();
          stageCmd.Stage = this.ghData.stage.toString();
          this.sendDeviceCmd('Agriculture_Control_Stage', stageCmd);
        }

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
  @State humidifierOpen: boolean = false;

  @State pumpStatusStr: string = 'OFF';
  @State fanStatusStr: string = 'OFF';
  @State ledStatusStr: string = 'OFF';
  @State humidifierStatusStr:string='OFF';

  @State thresholdSoil: number = 20;
  @State thresholdLight: number = 500;
  @State thresholdTemp: number = 32;
  @State thresholdHumi: number = 45;
  @State thresholdCO2: number = 1000;
  @State isPlaying: boolean = false;
  @State isAiLoading: boolean = false;
  async autoSetThresholds() {
    if (!this.ghData.crop || this.ghData.crop.trim() === '') {
      promptAction.showToast({ message: '请先点击大棚页面右上角齿轮图标设置种植作物！' });
      return;
    }
    if (this.ghData.stage === undefined || this.ghData.stage < 0) {
      promptAction.showToast({ message: '请先点击大棚页面右上角齿轮图标设置生长阶段！' });
      return;
    }

    let stages = ['育苗期', '生长期', '开花期', '结果期'];
    let stageName = stages[this.ghData.stage];

    this.isAiLoading = true;
    try {
      // 调取 AI 接口
      let aiResult = await AiService.getPlantInfo(this.ghData.crop, stageName);
      if (aiResult) {
        // 辅助方法：从类似 "25-30℃" 的字符串里提取所有数字
        let extractNums = (str: string) => {
          if (!str) return [];
          let matches = str.match(/\d+/g);
          return matches ? matches.map(Number) : [];
        };

        // 限取范围最小值，上限取范围最大值
        // 土壤湿度下限 (提取到的数字里取最小，且不超过100)
        let soilNums = extractNums(aiResult.soilMoisture);
        if (soilNums.length > 0) this.thresholdSoil = Math.min(100, Math.max(0, Math.min(...soilNums)));

        // 空气湿度下限
        let humiNums = extractNums(aiResult.airMoisture);
        if (humiNums.length > 0) this.thresholdHumi = Math.min(100, Math.max(0, Math.min(...humiNums)));

        // 光照强度下限
        let lightNums = extractNums(aiResult.light);
        if (lightNums.length > 0) this.thresholdLight = Math.min(100000, Math.max(0, Math.min(...lightNums)));

        // 空气温度上限 (提取到的数字里取最大，且不超过50℃)
        let tempNums = extractNums(aiResult.airTemp);
        if (tempNums.length > 0) this.thresholdTemp = Math.min(50, Math.max(0, Math.max(...tempNums)));

        // CO2上限
        let co2Nums = extractNums(aiResult.carbonDioxide);
        if (co2Nums.length > 0) this.thresholdCO2 = Math.min(5000, Math.max(0, Math.max(...co2Nums)));

        promptAction.showToast({ message: '✨ 已根据 AI 推荐更新阈值，请检查后点击“完成”保存' });
      } else {
        promptAction.showToast({ message: 'AI 分析失败或网络超时' });
      }
    } catch (err) {
      console.error('AI设置阈值异常', err);
      promptAction.showToast({ message: '请求异常，请检查网络' });
    } finally {
      this.isAiLoading = false;
    }
  }

  sendDeviceCmd(commandName: string, paras: Object) {
    if (!this.ghData.deviceId) {
      return;
    }
    IotService.sendCommand(this.ghData.deviceId, commandName, paras).then(success => {
      if (!success) {
        promptAction.showToast({ message: `${commandName} 指令执行异常，请检查设备。` });
      }
    });
  }

  saveAndSendThresholds() {
    animateTo({ duration: 300, curve: Curve.EaseIn }, () => { this.isDrawerOpen = false; });

    let thresholdCmd = new CmdThreshold();
    thresholdCmd.temp = this.thresholdTemp;
    thresholdCmd.humi = this.thresholdHumi;
    thresholdCmd.light = this.thresholdLight;
    thresholdCmd.soil = this.thresholdSoil;
    thresholdCmd.co2 = this.thresholdCO2;
    this.sendDeviceCmd('Agriculture_Set_Threshold', thresholdCmd);

    // 更新本地数据库中的阈值
    this.ghData.thresholdTemp = this.thresholdTemp;
    this.ghData.thresholdHumi = this.thresholdHumi;
    this.ghData.thresholdLight = this.thresholdLight;
    this.ghData.thresholdSoil = this.thresholdSoil;
    this.ghData.thresholdCO2 = this.thresholdCO2;

    DatabaseManager.updateGreenhouse(this.ghData).then(() => {
      promptAction.showToast({ message: '阈值已下发并保存' });
    });
  }

  forceVideoStyle(ctrl: webview.WebviewController) {
    let js = `
      var img = document.querySelector('img');
      if (img && img.getAttribute('data-styled') !== 'yes') {
        document.body.style.cssText = 'margin:0!important; padding:0!important; background-color:#000000!important; width:100vw!important; height:100vh!important; overflow:hidden!important; display:flex!important; justify-content:center!important; align-items:center!important;';
        img.style.cssText = 'width:100%!important; height:100%!important; object-fit:contain!important; margin:0!important; padding:0!important; max-width:none!important; max-height:none!important;';
        img.setAttribute('data-styled', 'yes');
      }
    `;
    try { ctrl.runJavaScript(js); } catch(e){}
  }

  @State styleTimer: number = -1;

  aboutToAppear() {
    this.fetchShadowData();
    this.styleTimer = setInterval(() => {
      if (!this.isPlaying) return;
      this.forceVideoStyle(this.controller);
      if (this.isFullScreen) {
        this.forceVideoStyle(this.fsController);
      }
    }, 500);
  }

  aboutToDisappear() {
    clearInterval(this.styleTimer);
    try {
      this.controller.loadUrl('about:blank');
      this.fsController.loadUrl('about:blank');
    } catch (e) {}
  }

  async toggleFullScreen(isFull: boolean) {
    try {
      if (isFull) {
        try {
          this.controller.stop();
          this.controller.loadUrl('about:blank');
        } catch(e) {}

        setTimeout(async () => {
          this.isFullScreen = true;
          let win = await window.getLastWindow(getContext(this));
          await win.setPreferredOrientation(window.Orientation.LANDSCAPE);
          await win.setWindowSystemBarEnable([]);

          setTimeout(() => {
            if (this.ghData.camUrl && this.isPlaying) {
              try { this.fsController.loadUrl(this.ghData.camUrl); } catch(e) {}
            }
          }, 100);
        }, 300);

      } else {
        try {
          this.fsController.stop();
          this.fsController.loadUrl('about:blank');
        } catch(e) {}

        setTimeout(async () => {
          this.isFullScreen = false;
          let win = await window.getLastWindow(getContext(this));
          await win.setPreferredOrientation(window.Orientation.PORTRAIT);
          await win.setWindowSystemBarEnable(['status', 'navigation']);

          setTimeout(() => {
            if (this.ghData.camUrl && this.isPlaying) {
              try { this.controller.loadUrl(this.ghData.camUrl); } catch(e) {}
            }
          }, 300);
        }, 300);
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
        this.humidifierStatusStr=res.data.HumidifierStatus;

        this.pumpOpen = res.data.PumpStatus === 'ON';
        this.fanOpen = res.data.FanStatus === 'ON';
        this.ledOpen = res.data.LedStatus === 'ON';
        this.humidifierOpen=res.data.HumidifierStatus==='ON';

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
        this.humidifierStatusStr='OFF'
      }
    } catch (e) {
      console.error("请求异常：", JSON.stringify(e));
    }
  }

  @Builder VideoContent(ctrl: webview.WebviewController) {
    if (this.ghData.camUrl) {
      Stack() {
        Web({ src: this.isPlaying ? this.ghData.camUrl : 'about:blank', controller: ctrl })
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .mediaPlayGestureAccess(false)
          .verticalScrollBarAccess(false)
          .horizontalScrollBarAccess(false)

        if (this.isPlaying) {
          Rect().width('100%').height('100%').fill(Color.Transparent)
            .onClick(() => {
              this.isPlaying = false;
              try {
                ctrl.stop();
                ctrl.loadUrl('about:blank');
              } catch (e) {}
            })
        }

        if (!this.isPlaying) {
          Stack() {
            Rect().width('100%').height('100%').fill(Color.Black)

            Stack() {
              Circle({ width: 64, height: 64 }).fill('rgba(255,255,255,0.2)')
              Circle({ width: 50, height: 50 }).fill('rgba(0,0,0,0.6)')
              Image($r('app.media.pause_icon'))
                .width(28)
                .height(28)
                .margin({ left: 4 })
            }
          }
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.isPlaying = true;
            try {
              ctrl.loadUrl(this.ghData.camUrl);
            } catch (e) {}
          })
        }
      }
    } else {
      Image($r('app.media.app_icon'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
  }

  build() {
    NavDestination() {
      Stack() {
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

              Text('⋮')
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#999')
                .padding({left: 10, right: 5, bottom: 5})
               // .width(24).height(24)
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

            Stack() {
              if (!this.isFullScreen) {
                this.VideoContent(this.controller)
              } else {
                Rect().width('100%').height('100%').fill(Color.Black)
              }

              Row({ space: 6 }) {
                Circle({ width: 8, height: 8 }).fill('#FF4D4F')
                Text('LIVE 实时监控').fontSize(12).fontColor(Color.White)
              }.position({ x: 10, y: 10 }).backgroundColor('#66000000').padding(6).borderRadius(12)

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
              ListItem() { HorizontalDataCard({ title: '土壤湿度', value: this.soilHum, unit: '%', colorCode: '#8CE200', isSystemOnline: this.isSystemOnline }) }
              ListItem() { HorizontalDataCard({ title: '光照强度', value: this.lightLux, unit: 'Lx', colorCode: '#FCC419', isSystemOnline: this.isSystemOnline }) }
              ListItem() { HorizontalDataCard({ title: 'CO2浓度', value: this.co2, unit: 'ppm', colorCode: '#A9A9A9', isSystemOnline: this.isSystemOnline }) }
            }
            .listDirection(Axis.Horizontal).scrollBar(BarState.Off).width('100%').height(90).padding({ left: 15, right: 15 })

            Row() {
              Text('设备控制台').fontSize(16).fontWeight(FontWeight.Bold)
              Blank()
              Row({ space: 8 }) {
                Text(this.isAutoMode ? '自动接管' : '手动干预').fontSize(14).fontColor(this.isAutoMode ? '#00B96B' : '#FF6B6B')
                Toggle({ type: ToggleType.Switch, isOn: this.isAutoMode }).onChange((isOn) => {
                  this.isAutoMode = isOn;
                  let modeCmd = new CmdMode();
                  modeCmd.Mode = isOn ? 'auto' : 'manual';
                  this.sendDeviceCmd('Agriculture_Control_Mode', modeCmd);
                })
              }
            }.width('100%').padding({ left: 15, right: 15, top: 25, bottom: 10 })

            Column() {
              DeviceControlItem({
                icon: '💦', name: '滴灌水泵', isOn: this.pumpOpen, isAuto: this.isAutoMode,
                autoText: `当土壤或空气湿度低于设定值时启动`, statusStr: this.pumpStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.pumpOpen = val;
                  let pumpCmd = new CmdPump();
                  pumpCmd.Pump = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Pump', pumpCmd);
                }
              })
              DeviceControlItem({
                icon: '☀️', name: 'LED补光灯', isOn: this.ledOpen, isAuto: this.isAutoMode,
                autoText: `当光照强度低于 ${this.thresholdLight}Lx 时启动`, statusStr: this.ledStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.ledOpen = val;
                  let ledCmd = new CmdLed();
                  ledCmd.Led = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Led', ledCmd);
                }
              })
              DeviceControlItem({
                icon: '💨', name: '通风排气扇', isOn: this.fanOpen, isAuto: this.isAutoMode,
                autoText: `当温度或CO2浓度高于设定值时启动`, statusStr: this.fanStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.fanOpen = val;
                  let fanCmd = new CmdFan();
                  fanCmd.Fan = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Fan', fanCmd);
                }
              })
              DeviceControlItem({
                icon: '💨', name: '农药喷湿器', isOn: this.humidifierOpen, isAuto: this.isAutoMode,
                autoText: `手动接管模式下自由控制`, statusStr: this.humidifierStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.humidifierOpen = val;
                  let humiCmd = new CmdHumidifier();
                  humiCmd.Humidifier = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Humidifier', humiCmd);
                }
              })
            }.padding({ left: 15, right: 15, bottom: 40 })

          }.width('100%')
        }
        .width('100%').height('100%').backgroundColor('#F5F7FA')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

        if (this.isAutoMode && !this.isDrawerOpen && !this.isFullScreen) {
          Row() { Text('< 设置阈值').fontSize(12).fontColor(Color.White).fontWeight(FontWeight.Bold) }
          .backgroundColor('#00B96B').padding({ left: 12, right: 8, top: 12, bottom: 12 }).borderRadius({ topLeft: 20, bottomLeft: 20 })
          .position({ right: 0, top: '45%' }).shadow({ radius: 6, color: '#4400B96B', offsetX: -2, offsetY: 2 })
          .onClick(() => { animateTo({ duration: 350, curve: Curve.FastOutSlowIn }, () => { this.isDrawerOpen = true; }) })
        }

        if (this.isDrawerOpen && !this.isFullScreen) {
          Row().width('100%').height('100%').backgroundColor('rgba(0,0,0,0.5)')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .onClick(() => {
              animateTo({ duration: 300, curve: Curve.EaseIn }, () => { this.isDrawerOpen = false; })
            }).zIndex(10)

          Column() {
            Row() {
              Text('自动触发阈值').fontSize(20).fontWeight(FontWeight.Bold)
              Blank()


              if (this.isAiLoading) {
                LoadingProgress().width(20).height(20).color('#00B96B').margin({ right: 15 })
              } else {
                Text('✨ 智能推荐').fontColor('#FCC419').fontSize(14).fontWeight(FontWeight.Bold)
                  .margin({ right: 15 })
                  .onClick(() => { this.autoSetThresholds(); })
              }

              Text('完成').fontColor('#00B96B').fontSize(16).fontWeight(FontWeight.Medium)
                .onClick(() => { this.saveAndSendThresholds(); })
            }.width('100%').padding({ top: 50, bottom: 20, left: 20, right: 20 })

            Scroll() {
              Column({ space: 15 }) {
                Column() { Row() { Text('🌱 土壤湿度下限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdSoil}%`).fontColor('#00B96B').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdSoil, min: 0, max: 100 }).selectedColor('#00B96B').onChange((v) => this.thresholdSoil = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('💧 空气湿度下限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdHumi}%`).fontColor('#4DABF7').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdHumi, min: 0, max: 100 }).selectedColor('#4DABF7').onChange((v) => this.thresholdHumi = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('☀️ 光照强度下限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdLight}Lx`).fontColor('#FCC419').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdLight, min: 0, max: 100000 }).selectedColor('#FCC419').onChange((v) => this.thresholdLight = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('🌡️ 空气温度上限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdTemp}℃`).fontColor('#FF6B6B').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdTemp, min: 0, max: 50 }).selectedColor('#FF6B6B').onChange((v) => this.thresholdTemp = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
                Column() { Row() { Text('💨 CO2浓度上限').fontSize(14).fontWeight(FontWeight.Medium); Blank(); Text(`${this.thresholdCO2}ppm`).fontColor('#A9A9A9').fontWeight(FontWeight.Bold) }.width('100%'); Slider({ value: this.thresholdCO2, min: 0, max: 5000 }).selectedColor('#A9A9A9').onChange((v) => this.thresholdCO2 = Math.round(v)) }.padding(15).backgroundColor(Color.White).borderRadius(12)
              }.width('100%').padding({ left: 15, right: 15, bottom: 40 })
            }.scrollBar(BarState.Off).layoutWeight(1)
          }
          .width('85%').height('100%').backgroundColor('#F5F7FA').expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .position({ right: 0, top: 0 }).transition(TransitionEffect.move(TransitionEdge.END)).zIndex(11)
        }

        if (this.isFullScreen) {
          Stack() {
            this.VideoContent(this.fsController)
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
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .zIndex(999)
        }

      }.width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .onReady((ctx) => {
      this.pathStack = ctx.pathStack;
    })
    .onBackPressed(() => {
      if (this.isFullScreen) {
        this.toggleFullScreen(false);
        return true;
      }
      return false;
    })
  }
}