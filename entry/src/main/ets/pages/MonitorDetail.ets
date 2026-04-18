import { promptAction } from '@kit.ArkUI';
import { EnvRecordModel, GreenhouseModel } from '../model/GreenhouseModel';
import { DeviceInfo, IotService } from '../services/iot/IotService';
import { DatabaseManager } from '../data/DatabaseManager';
import window from '@ohos.window';
import { webview } from '@kit.ArkWeb';
import { AiService } from '../services/ai/AIService';
import { Chart } from '../components/Chart';

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
  @Prop icon: Resource;
  @Prop name: string = '';
  @Prop isOn: boolean = false;
  @Prop isAuto: boolean = false;
  @Prop autoText: string = '';
  @Prop statusStr: string = '';
  @Prop isSystemOnline: boolean = false;
  onChangeCb: (val: boolean) => void = () => {};
  onTimerCb: () => void = () => {};

  build() {
    Column() {
      Row() {
        Row({ space: 8 }) {
          if (this.isOn) {
            Image(this.icon)
              .width(22)
              .height(22)
          } else {
            Image(this.icon)
              .width(22)
              .height(22)
              .fillColor('#999999')
          }
          Text(this.name).fontSize(16).fontWeight(FontWeight.Medium)
        }

        if (!this.isSystemOnline) {
          Row({ space: 4 }) {
            Circle({ width: 6, height: 6 }).fill('#FF4D4F')
            Text('不在线').fontSize(12).fontColor('#FF4D4F')
          }.margin({ left: 8 })
        }

        Blank()

        if (this.isAuto) {
          Text('由系统自动托管').fontSize(12).fontColor('#00B96B').margin({ right: 10 })
        } else {
          Text('⏱️定时')
            .fontSize(12)
            .fontColor('#2196F3')
            .backgroundColor('#E3F2FD')
            .padding({left: 8, right: 8, top: 4, bottom: 4})
            .borderRadius(12)
            .margin({ right: 10 })
            .onClick(() => {
              this.onTimerCb();
            })
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

  // 存储云端查询下来的设备列表
  @State remoteDevices: DeviceInfo[] = [];

  aboutToAppear() {
    // 弹窗打开时，自动去云端拉取已有设备
    IotService.getDeviceList().then(res => {
      this.remoteDevices = res;
    });
  }

  @Builder
  DeviceMenuBuilder() {
    Menu() {
      if (this.remoteDevices.length === 0) {
        MenuItem({ content: '正在加载或无设备...' })
      } else {
        ForEach(this.remoteDevices, (dev: DeviceInfo, index: number) => {
          MenuItem() {
            Column() {
              Text(`${dev.device_name} \n(ID: ${dev.device_id})`)
                .fontSize(15)
                .fontColor('#333')
                .width('100%')
                .padding({ top: 12, bottom: 12 })

              if (index < this.remoteDevices.length - 1) {
                Divider()
                  .strokeWidth(1)
                  .color('#ffcac7c7')
              }
            }.width('100%')
          }
          .onClick(() => {
            // 选中后，直接自动填充 ID
            this.ghData.deviceId = dev.device_id;
            if (!this.ghData.name) {
              this.ghData.name = dev.device_name;
            }
          })
        })
      }
    }
  }

  build() {
    Column({ space: 15 }) {
      Text('编辑大棚信息').fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '大棚名称 (必填)', text: this.ghData.name })
        .onChange((val) => this.ghData.name = val)
      Stack({ alignContent: Alignment.End }) {
        TextInput({ placeholder: '网关设备ID (必填)', text: this.ghData.deviceId })
          .onChange((val) => this.ghData.deviceId = val)
          .width('100%')

        // 箭头触发区域
        Row() {
          Text('▼')
            .fontSize(12)
            .fontColor('#999')
        }
        .padding({ left: 15, right: 15, top: 12, bottom: 12 }) // 给足点击区域
        .bindMenu(this.DeviceMenuBuilder()) // 绑定菜单
      }.width('100%')
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
  @State chartRecords: EnvRecordModel[] = [];
  @State currentMetric: string = 'temp'; // 当前选中的指标
  @State currentTimeRange: number = 24; // 24小时 / 168小时(7天)
  @State metricColor: string = '#FF6B6B'; // 当前折线颜色
  async loadChartData() {
    let mockData: EnvRecordModel[] = [];
    let now = new Date();
    // 获取今天 00:00:00 的绝对时间戳
    let startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();

    if (this.currentTimeRange === 24) {
      //24小时模式：强制从 00:00 到 24:00， 25 个点
      for (let i = 0; i <= 24; i++) {
        let r = new EnvRecordModel();
        r.timestamp = startOfToday + i * 3600000;

        let h = i;
        let isDay = h >= 6 && h <= 18;


        if (isDay) {
          let sun = Math.sin(((h - 6) / 12) * Math.PI);
          r.light = Math.floor(sun * 65000 + Math.random() * 3000);
        } else {
          r.light = Math.floor(Math.random() * 20);
        }

        let baseTemp = isDay ? 26 : 17;
        let tempWave = isDay ? Math.sin(((h - 6) / 12) * Math.PI) * 6 : Math.random() * 2;
        r.temp = Number((baseTemp + tempWave + Math.random() * 1.5).toFixed(1));

        let baseHumi = isDay ? 65 : 88;
        r.humi = Number((baseHumi - (r.temp - 20) * 1.2 + Math.random() * 4).toFixed(1));

        r.soil = Number((48 + Math.sin(i/2) * 3 + Math.random() * 2).toFixed(1));

        let baseCo2 = isDay ? 420 : 850;
        r.co2 = Math.floor(baseCo2 + Math.random() * 60);

        mockData.push(r);
      }
    } else {
      // 7天模式：模拟日均值/日最高值的宏观趋势
      for (let i = 7; i >= 0; i--) {
        let r = new EnvRecordModel();
        // 每天取一个点代表当天的聚合数据
        r.timestamp = startOfToday - i * 86400000 + 12 * 3600000;

        // 模拟前几天是阴天，这两天放晴（光照日最高值）
        r.light = i > 2 ? Math.floor(15000 + Math.random() * 5000) : Math.floor(60000 + Math.random() * 5000);
        // 模拟最近一周气温逐渐回暖（日均温）
        r.temp = Number((20 + (7 - i) * 1.5 + Math.random() * 2).toFixed(1));
        // 湿度跟温度反相关，逐渐降低
        r.humi = Number((75 - (7 - i) * 2 + Math.random() * 3).toFixed(1));
        // 模拟土壤湿度连续几天慢慢干涸，突然在昨天(i=1)浇了水，飙升的趋势
        if (i > 1) {
          r.soil = Number((50 - (7 - i) * 4 + Math.random() * 2).toFixed(1)); // 一天比一天干
        } else {
          r.soil = Number((65 + Math.random() * 2).toFixed(1)); // 刚浇完水
        }
        // CO2日均值比较平稳
        r.co2 = Math.floor(500 + Math.random() * 30);

        mockData.push(r);
      }
    }

    this.chartRecords = mockData;


    // if (!this.ghData.id) return;
    // this.chartRecords = await DatabaseManager.getEnvRecords(this.ghData.id, this.currentTimeRange);
  }
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

        promptAction.showToast({ message: '✨ 已自动推荐更新阈值，请检查后点击“完成”保存' });
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
  @State activeTimers: Map<string, number> = new Map();

  // 唤起系统时间选择器，并计算延迟时间
  showCustomTimerDialog(deviceName: string, cmdKey: string, onCmdVal: string, offCmdVal: string) {
    promptAction.showActionMenu({
      title: `请选择 ${deviceName} 定时操作`,
      buttons: [
        { text: '定时开启', color: '#00B96B' },
        { text: '定时关闭', color: '#FF4D4F' }
      ]
    }).then((data) => {
      let isTurnOn = data.index === 0;
      let actionText = isTurnOn ? '开启' : '关闭';
      let cmdValue = isTurnOn ? onCmdVal : offCmdVal;

      // 调起 时间滑动选择器
      TimePickerDialog.show({
        useMilitaryTime: true, // 24小时制
        onAccept: (value: TimePickerResult) => {
          let now = new Date();
          let target = new Date();
          target.setHours(value.hour, value.minute, 0, 0);

          //时间比现在还早，默认明天
          if (target.getTime() <= now.getTime()) {
            target.setDate(target.getDate() + 1);
          }

          let delayMs = target.getTime() - now.getTime();
          let timeStr = `${value.hour < 10 ? '0'+value.hour : value.hour}:${value.minute < 10 ? '0'+value.minute : value.minute}`;

          // 组装对应的命令对象
          let cmdObj: Object;
          if (cmdKey === 'Agriculture_Control_Pump') {
            let c = new CmdPump(); c.Pump = cmdValue; cmdObj = c;
          } else if (cmdKey === 'Agriculture_Control_Led') {
            let c = new CmdLed(); c.Led = cmdValue; cmdObj = c;
          } else if (cmdKey === 'Agriculture_Control_Fan') {
            let c = new CmdFan(); c.Fan = cmdValue; cmdObj = c;
          } else {
            let c = new CmdHumidifier(); c.Humidifier = cmdValue; cmdObj = c;
          }

          this.executeSchedule(deviceName, cmdKey, cmdObj, delayMs, `${timeStr} ${actionText}`);
        }
      });
    });
  }

  // 执行倒计时发送
  executeSchedule(deviceName: string, cmdKey: string, cmdObject: Object, delayMs: number, desc: string) {
    promptAction.showToast({ message: `设置成功：${deviceName} 将于 ${desc}` });

    let timerId = setTimeout(() => {
      if (this.isAutoMode) {
        promptAction.showDialog({
          title: '定时任务已取消',
          message: `原定于执行的 [${deviceName}] 控制命令，因当前大棚已切换为【自动接管】模式被拦截，防止冲突。`,
          buttons: [{ text: '知道了', color: '#00B96B' }]
        });
        return;
      }
      this.sendDeviceCmd(cmdKey, cmdObject);
      promptAction.showToast({ message: `⏰ 定时任务触发：${deviceName} 已${desc.includes('开启')?'开启':'关闭'}` });
      this.activeTimers.delete(cmdKey);
    }, delayMs);

    if (this.activeTimers.has(cmdKey)) {
      clearTimeout(this.activeTimers.get(cmdKey));
    }
    this.activeTimers.set(cmdKey, timerId);
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
  async checkAndAdvanceStage() {
    if (!this.ghData.autoStageEnabled || this.ghData.nextStageTime <= 0) return;

    let now = Date.now();
    if (now >= this.ghData.nextStageTime) {
      // 时间到了！
      if (this.ghData.stage < 3) { // 0:育苗, 1:生长, 2:开花, 3:结果
        let nextStage = this.ghData.stage + 1;
        let stages = ['育苗期', '生长期', '开花期', '结果期'];
        let stageName = stages[nextStage];

        promptAction.showToast({ message: `自动流转触发：正在为您规划【${stageName}】方案...` });

        try {
          let aiResult = await AiService.getPlantInfo(this.ghData.crop, stageName);
          if (aiResult) {
            // 1. 更新阶段
            this.ghData.stage = nextStage;
            // 2. 提取新阈值 (复用你之前的提取逻辑)
            let extractNums = (str: string) => {
              let matches = str.match(/\d+/g); return matches ? matches.map(Number) : [];
            };
            let tempNums = extractNums(aiResult.airTemp);
            if (tempNums.length > 0) this.thresholdTemp = Math.min(50, Math.max(0, Math.max(...tempNums)));

            let humiNums = extractNums(aiResult.airMoisture);
            if (humiNums.length > 0) this.thresholdHumi = Math.min(100, Math.max(0, Math.min(...humiNums)));

            let soilNums = extractNums(aiResult.soilMoisture);
            if (soilNums.length > 0) this.thresholdSoil = Math.min(100, Math.max(0, Math.min(...soilNums)));

            let lightNums = extractNums(aiResult.light);
            if (lightNums.length > 0) this.thresholdLight = Math.min(100000, Math.max(0, Math.min(...lightNums)));

            let co2Nums = extractNums(aiResult.carbonDioxide);
            if (co2Nums.length > 0) this.thresholdCO2 = Math.min(5000, Math.max(0, Math.max(...co2Nums)));

            // 计算下一次的时间戳 (天数 * 24小时 * 60分 * 60秒 * 1000毫秒)
            let days = aiResult.durationDays > 0 ? aiResult.durationDays : 15;
            this.ghData.nextStageTime = Date.now() + (days * 86400000);

            // 测试
            // this.ghData.nextStageTime = Date.now() + 60000;

            // 下发给设备端
            let stageCmd = new CmdStage();
            stageCmd.Stage = this.ghData.stage.toString();
            this.sendDeviceCmd('Agriculture_Control_Stage', stageCmd);
            this.saveAndSendThresholds();

            promptAction.showToast({ message: `已自动进入【${stageName}】，下一次变更为 ${days} 天后` });
          }
        } catch (e) {
          console.error('自动流转失败', e);
        }
      } else {
        // 如果已经是最后阶段（结果期），流转结束，自动关闭该功能
        this.ghData.autoStageEnabled = false;
        this.ghData.nextStageTime = 0;
        DatabaseManager.updateGreenhouse(this.ghData);
        promptAction.showToast({ message: '种植周期已完成！' });
      }
    }
  }
  aboutToAppear() {
     //优先读本地
    this.thresholdTemp = this.ghData.thresholdTemp ?? 32;
    this.thresholdHumi = this.ghData.thresholdHumi ?? 45;
    this.thresholdLight = this.ghData.thresholdLight ?? 500;
    this.thresholdSoil = this.ghData.thresholdSoil ?? 20;
    this.thresholdCO2 = this.ghData.thresholdCO2 ?? 1000;
    //云端做校验
    this.fetchShadowData();
    //AI 智能托管
    this.checkAndAdvanceStage();
    this.loadChartData();
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
      // 进入全屏模式
      if (isFull) {
        try {
          this.controller.stop();// 停止小窗口播放
          this.controller.loadUrl('about:blank');
        } catch(e) {}

        setTimeout(async () => {
          this.isFullScreen = true;
          let win = await window.getLastWindow(getContext(this));
          await win.setPreferredOrientation(window.Orientation.LANDSCAPE);// 横屏
          await win.setWindowSystemBarEnable([]);//隐藏状态栏

          setTimeout(() => {
            if (this.ghData.camUrl && this.isPlaying) {
              try { this.fsController.loadUrl(this.ghData.camUrl); } catch(e) {}
            }
          }, 100);
        }, 300);

      } else {
        try {
          // 退出全屏
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
              // 恢复小窗播放
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
        if (this.ghData.id) {
          await DatabaseManager.insertEnvRecord(
            this.ghData.id,
            Number(this.airTemp),
            Number(this.airHum),
            Number(this.soilHum),
            Number(this.lightLux),
            Number(this.co2)
          );
          this.loadChartData();
        }
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
    if (this.ghData.camUrl) {// 检查是否存在摄像头地址
      Stack() {
        //Web组件加载视频流
        Web({ src: this.isPlaying ? this.ghData.camUrl : 'about:blank', controller: ctrl })
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Black)// 视频背景设为黑色
          .javaScriptAccess(true)// 启用JS交互
          .domStorageAccess(true) // 启用本地存储
          .mediaPlayGestureAccess(false) // 禁止手势控制（防误触）
          .verticalScrollBarAccess(false) // 隐藏滚动条
          .horizontalScrollBarAccess(false)// 隐藏滚动条

        if (this.isPlaying) {
          //通过透明覆盖层实现点击停止播放
          Rect().width('100%').height('100%').fill(Color.Transparent)
            .onClick(() => {// 点击停止播放
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
              Column({ space: 6 }) {
                // 大棚名称
                Text(this.ghData.name).fontSize(22).fontWeight(FontWeight.Bold)

                Text(`作物: ${this.ghData.crop || '未设置'}`)
                  .fontSize(14)
                  .fontColor('#666')

                Row({ space: 8 }) {
                  if (this.ghData.stage !== undefined && this.ghData.stage >= 0) {
                    Text(['🌱 育苗期', '🌿 生长期', '🌸 开花期', '🍅 结果期'][this.ghData.stage])
                      .fontSize(12).fontColor('#00B96B').backgroundColor('#E6F8F0')
                      .padding({ left: 6, right: 6, top: 3, bottom: 3 }).borderRadius(4)
                  }

                  if (this.ghData.plantTime && this.ghData.plantTime > 0) {
                    Text(`已种植 ${Math.max(1, Math.ceil((Date.now() - this.ghData.plantTime) / 86400000))} 天`)
                      .fontSize(12).fontColor('#FF6B6B').backgroundColor('#FFEDED')
                      .padding({ left: 6, right: 6, top: 3, bottom: 3 }).borderRadius(4)
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
                icon: $r('app.media.ic_pump'),
                name: '滴灌水泵', isOn: this.pumpOpen, isAuto: this.isAutoMode,
                autoText: `当土壤或空气湿度低于设定值时启动`, statusStr: this.pumpStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.pumpOpen = val;
                  let pumpCmd = new CmdPump();
                  pumpCmd.Pump = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Pump', pumpCmd);
                },
                onTimerCb: () => { this.showCustomTimerDialog('滴灌水泵', 'Agriculture_Control_Pump', 'ON', 'OFF'); }
              })
              DeviceControlItem({
                icon: $r('app.media.ic_led'),
                name: 'LED补光灯', isOn: this.ledOpen, isAuto: this.isAutoMode,
                autoText: `当光照强度低于 ${this.thresholdLight}Lx 时启动`, statusStr: this.ledStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.ledOpen = val;
                  let ledCmd = new CmdLed();
                  ledCmd.Led = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Led', ledCmd);
                },
                onTimerCb: () => { this.showCustomTimerDialog('LED补光灯', 'Agriculture_Control_Led', 'ON', 'OFF'); }
              })
              DeviceControlItem({
                icon: $r('app.media.ic_fan'),
                name: '通风排气扇', isOn: this.fanOpen, isAuto: this.isAutoMode,
                autoText: `当温度或CO2浓度高于设定值时启动`, statusStr: this.fanStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.fanOpen = val;
                  let fanCmd = new CmdFan();
                  fanCmd.Fan = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Fan', fanCmd);
                },
                onTimerCb: () => { this.showCustomTimerDialog('通风排气扇', 'Agriculture_Control_Fan', 'ON', 'OFF'); }
              })
              DeviceControlItem({
                icon: $r('app.media.ic_humidifier'),
                name: '农药喷湿器', isOn: this.humidifierOpen, isAuto: this.isAutoMode,
                autoText: `手动接管模式下自由控制`, statusStr: this.humidifierStatusStr, isSystemOnline: this.isSystemOnline,
                onChangeCb: (val: boolean) => {
                  this.humidifierOpen = val;
                  let humiCmd = new CmdHumidifier();
                  humiCmd.Humidifier = val ? 'ON' : 'OFF';
                  this.sendDeviceCmd('Agriculture_Control_Humidifier', humiCmd);
                },
                onTimerCb: () => { this.showCustomTimerDialog('农药喷湿器', 'Agriculture_Control_Humidifier', 'ON', 'OFF'); }
              })
            }.padding({ left: 15, right: 15, bottom: 40 })
            Column() {
              Row() {
                Text('监测统计').fontSize(16).fontWeight(FontWeight.Bold)
                Blank()
                Select([{value:'最近24小时'}, {value:'最近7天'}])
                  .selected(this.currentTimeRange === 24 ? 0 : 1)
                  .value(this.currentTimeRange === 24 ? '最近24小时' : '最近7天')
                  .onSelect((idx) => {
                    this.currentTimeRange = idx === 0 ? 24 : 168; // 168小时即7天
                    this.loadChartData();
                  })
              }.width('100%').padding({ bottom: 10 })

              // 指标切换栏
              // 指标切换栏
              Row({ space: 8 }) { // 间距调小一点点，保证5个按钮放得下
                Text('温度').fontSize(13).fontColor(this.currentMetric==='temp'?'#FFF':'#666').backgroundColor(this.currentMetric==='temp'?'#FF6B6B':'#EEE').padding({left:10,right:10,top:5,bottom:5}).borderRadius(12)
                  .onClick(()=>{ this.currentMetric='temp'; this.metricColor='#FF6B6B'; })

                Text('湿度').fontSize(13).fontColor(this.currentMetric==='humi'?'#FFF':'#666').backgroundColor(this.currentMetric==='humi'?'#4DABF7':'#EEE').padding({left:10,right:10,top:5,bottom:5}).borderRadius(12)
                  .onClick(()=>{ this.currentMetric='humi'; this.metricColor='#4DABF7'; })

                Text('土壤').fontSize(13).fontColor(this.currentMetric==='soil'?'#FFF':'#666').backgroundColor(this.currentMetric==='soil'?'#8CE200':'#EEE').padding({left:10,right:10,top:5,bottom:5}).borderRadius(12)
                  .onClick(()=>{ this.currentMetric='soil'; this.metricColor='#8CE200'; })

                Text('光照').fontSize(13).fontColor(this.currentMetric==='light'?'#FFF':'#666').backgroundColor(this.currentMetric==='light'?'#FCC419':'#EEE').padding({left:10,right:10,top:5,bottom:5}).borderRadius(12)
                  .onClick(()=>{ this.currentMetric='light'; this.metricColor='#FCC419'; })
                Text('CO2').fontSize(13).fontColor(this.currentMetric==='co2'?'#FFF':'#666').backgroundColor(this.currentMetric==='co2'?'#A9A9A9':'#EEE').padding({left:10,right:10,top:5,bottom:5}).borderRadius(12)
                  .onClick(()=>{ this.currentMetric='co2'; this.metricColor='#A9A9A9'; })
              }.width('100%').margin({ bottom: 15 })

              Chart({
                records: this.chartRecords,
                metricType: this.currentMetric,
                colorHex: this.metricColor
              })
            }
            .width('100%')
            .padding({ left: 15, right: 15, top: 20, bottom: 40 })
            .backgroundColor(Color.White)
            .borderRadius({ topLeft: 16, topRight: 16 })
            .shadow({ radius: 10, color: '#05000000', offsetY: -5 })

          }.width('100%')
        }
        .scrollBar(BarState.Off)
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
                Text('✨ 智能推荐')
                // 如果开启了托管，按钮变灰；否则为黄色
                  .fontColor(this.ghData.autoStageEnabled ? '#CCCCCC' : '#FCC419')
                  .fontSize(14).fontWeight(FontWeight.Bold)
                  .margin({ right: 15 })
                  .onClick(() => {
                    // 判断：如果开启了全周期托管，则拦截点击并提示
                    if (this.ghData.autoStageEnabled) {
                      promptAction.showToast({ message: '当前处于全周期托管中，系统会自动管理阈值，无需手动推荐' });
                      return;
                    }
                    // 没开启托管，正常调用之前的推荐接口
                    this.autoSetThresholds();
                  })
              }

              Text('完成').fontColor('#00B96B').fontSize(16).fontWeight(FontWeight.Medium)
                .onClick(() => { this.saveAndSendThresholds(); })
            }.width('100%').padding({ top: 50, bottom: 20, left: 20, right: 20 })

            Row() {
              Column({space: 4}) {

                Row({ space: 6 }) {
                  Image($r('app.media.ai_chat_icon'))
                    .width(18)
                    .height(18)
                    .objectFit(ImageFit.Contain)

                  Text('开启AI全生命周期托管')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333')
                }

                Text('自动计算当前阶段天数，到期自动进入下一阶段并更新阈值')
                  .fontSize(11)
                  .fontColor('#999')
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)

              Toggle({ type: ToggleType.Switch, isOn: this.ghData.autoStageEnabled })
                .selectedColor('#FCC419')
                .onChange(async (isOn) => {
                  this.ghData.autoStageEnabled = isOn;
                  if (isOn) {
                    if (this.ghData.stage < 0 || !this.ghData.crop) {
                      promptAction.showToast({ message: '请先在大棚设置中指定作物和当前生长阶段！' });
                      this.ghData.autoStageEnabled = false;
                      return;
                    }
                    // 开启时，立即规划当前阶段方案
                    promptAction.showToast({ message: '正在为您规划当前阶段最佳方案...' });
                    let stages = ['育苗期', '生长期', '开花期', '结果期'];
                    let aiResult = await AiService.getPlantInfo(this.ghData.crop, stages[this.ghData.stage]);

                    if (aiResult) {
                      let extractNums = (str: string) => {
                        let matches = str.match(/\d+/g); return matches ? matches.map(Number) : [];
                      };
                      let tempNums = extractNums(aiResult.airTemp);
                      if (tempNums.length > 0) this.thresholdTemp = Math.min(50, Math.max(0, Math.max(...tempNums)));

                      let humiNums = extractNums(aiResult.airMoisture);
                      if (humiNums.length > 0) this.thresholdHumi = Math.min(100, Math.max(0, Math.min(...humiNums)));

                      let soilNums = extractNums(aiResult.soilMoisture);
                      if (soilNums.length > 0) this.thresholdSoil = Math.min(100, Math.max(0, Math.min(...soilNums)));

                      let lightNums = extractNums(aiResult.light);
                      if (lightNums.length > 0) this.thresholdLight = Math.min(100000, Math.max(0, Math.min(...lightNums)));

                      let co2Nums = extractNums(aiResult.carbonDioxide);
                      if (co2Nums.length > 0) this.thresholdCO2 = Math.min(5000, Math.max(0, Math.max(...co2Nums)));

                      // 更新大棚对象的阈值
                      this.ghData.thresholdTemp = this.thresholdTemp;
                      this.ghData.thresholdHumi = this.thresholdHumi;
                      this.ghData.thresholdLight = this.thresholdLight;
                      this.ghData.thresholdSoil = this.thresholdSoil;
                      this.ghData.thresholdCO2 = this.thresholdCO2;

                      // 立刻下发新阈值给网关设备
                      let thresholdCmd = new CmdThreshold();
                      thresholdCmd.temp = this.thresholdTemp;
                      thresholdCmd.humi = this.thresholdHumi;
                      thresholdCmd.light = this.thresholdLight;
                      thresholdCmd.soil = this.thresholdSoil;
                      thresholdCmd.co2 = this.thresholdCO2;
                      this.sendDeviceCmd('Agriculture_Set_Threshold', thresholdCmd);

                      //计算天数并保存到数据库
                      let days = aiResult.durationDays > 0 ? aiResult.durationDays : 15;
                      this.ghData.nextStageTime = Date.now() + (days * 86400000);

                      DatabaseManager.updateGreenhouse(this.ghData);
                      promptAction.showToast({ message: `托管已开启！已同步AI阈值，本阶段将持续 ${days} 天` });
                    }
                  } else {
                    // 关闭托管时，清除时间限制
                    this.ghData.nextStageTime = 0;
                    DatabaseManager.updateGreenhouse(this.ghData);
                    promptAction.showToast({ message: '已关闭全周期托管' });
                  }
                })
            }
            .width('100%').padding({ left: 20, right: 20, bottom: 15 })

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