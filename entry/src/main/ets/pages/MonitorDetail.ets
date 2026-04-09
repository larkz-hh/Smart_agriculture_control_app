import {  } from '../data/DatabaseManager';
import { GreenhouseModel } from '../model/GreenhouseModel';

@Builder
export function MonitorDetailBuilder(name: string, param: Object) {
  MonitorDetail({ ghData: param as GreenhouseModel })
}
@Preview
@Component
export struct MonitorDetail {
  pathStack: NavPathStack = new NavPathStack();
  @State ghData: GreenhouseModel = new GreenhouseModel();

  // --- 模拟传感器数据 ---
  @State airTemp: string = '26.5';
  @State airHum: string = '45';
  @State soilHum: string = '32';
  @State lightLux: string = '850';
  @State co2: string = '410';

  // --- 控制状态 ---
  @State isAutoMode: boolean = true; // 全局自动/手动切换

  @State pumpOpen: boolean = false;
  @State ledOpen: boolean = true;
  @State fanOpen: boolean = false; // 新增风扇

  // 自动触发的阈值设置
  @State thresholdSoil: number = 20; // 湿度<20开水泵
  @State thresholdLight: number = 500; // 光照<500开灯
  @State thresholdTemp: number = 32; // 温度>32开风扇

  // 横向滚动的数据卡片
  @Builder HorizontalDataCard(title: string, value: string, unit: string, color: string) {
    Column() {
      Text(title).fontSize(14).fontColor('#666').margin({ bottom: 8 })
      Row({ space: 2 }) {
        Text(value).fontSize(26).fontWeight(FontWeight.Bold).fontColor(color)
        Text(unit).fontSize(12).fontColor('#999').margin({ bottom: 4 })
      }.alignItems(VerticalAlign.Bottom)
    }
    .width(110).height(80).backgroundColor(Color.White).borderRadius(12)
    .justifyContent(FlexAlign.Center).margin({ right: 10 })
    .shadow({ radius: 4, color: '#05000000', offsetY: 2 })
  }


  @Builder DeviceControlItem(icon: string, name: string, isOn: boolean, isAuto: boolean, autoText: string, onChange: (val: boolean) => void) {
    Column() {
      Row() {
        Text(`${icon} ${name}`).fontSize(16).fontWeight(FontWeight.Medium)
        Blank()
        if (isAuto) {
          Text('由系统自动托管').fontSize(12).fontColor('#00B96B').margin({ right: 10 })
        }
        Toggle({ type: ToggleType.Switch, isOn: isOn })
          .selectedColor('#00B96B')
          .enabled(!isAuto)
          .onChange(onChange)
      }.width('100%')

      if (isAuto) {
        Row() {
          Text('自动触发规则:').fontSize(12).fontColor('#999')
          Text(autoText).fontSize(12).fontColor('#FF6B6B').margin({ left: 4 })
        }.width('100%').margin({ top: 8 })
      }
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ bottom: 10 })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          Row() {
            Column({ space: 4 }) {
              Text(this.ghData.name).fontSize(22).fontWeight(FontWeight.Bold)
              Row({ space: 8 }) {
                // 处理作物为空的情况
                Text(`作物: ${this.ghData.crop || '未设置'}`).fontSize(14).fontColor('#666')

                //处理阶段未选择的情况
                if (this.ghData.stage !== undefined && this.ghData.stage >= 0) {
                  Text(['育苗期', '生长期', '开花期', '结果期'][this.ghData.stage])
                    .fontSize(12).fontColor('#00B96B').backgroundColor('#E6F8F0')
                    .padding({ left: 4, right: 4, top: 2, bottom: 2 }).borderRadius(4)
                }
              }
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Image($r('app.media.app_icon')).width(24).height(24) // 编辑入口
          }.width('100%').padding(15)

          // 视频监控区
          Stack() {
            Image($r('app.media.app_icon')) // 
              .width('100%').height(200).objectFit(ImageFit.Cover)
            Row({ space: 6 }) {
              Circle({ width: 8, height: 8 }).fill('#FF4D4F')
              Text('LIVE 实时监控').fontSize(12).fontColor(Color.White)
            }
            .position({ x: 10, y: 10 }).backgroundColor('#66000000').padding(6).borderRadius(12)
          }.width('92%').height(200).backgroundColor('#000').borderRadius(16).clip(true)

          Text('环境数据监测').fontSize(16).fontWeight(FontWeight.Bold).width('100%').padding({ left: 15, top: 20, bottom: 10 })

          List() {
            ListItem() { this.HorizontalDataCard('空气温度', this.airTemp, '℃', '#FF6B6B') }
            ListItem() { this.HorizontalDataCard('空气湿度', this.airHum, '%', '#4DABF7') }
            ListItem() { this.HorizontalDataCard('土壤湿度', this.soilHum, '%', '#8CE200') }
            ListItem() { this.HorizontalDataCard('光照强度', this.lightLux, 'Lx', '#FCC419') }
            ListItem() { this.HorizontalDataCard('CO2浓度', this.co2, 'ppm', '#A9A9A9') }
          }
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%').height(85).padding({ left: 15, right: 15 })

          // 控制中心 (手动/自动模式)
          Row() {
            Text('设备控制台').fontSize(16).fontWeight(FontWeight.Bold)
            Blank()
            Row({ space: 8 }) {
              Text(this.isAutoMode ? '自动接管' : '手动干预').fontSize(14).fontColor(this.isAutoMode ? '#00B96B' : '#FF6B6B')
              Toggle({ type: ToggleType.Switch, isOn: this.isAutoMode })
                .onChange((isOn) => this.isAutoMode = isOn)
            }
          }.width('100%').padding({ left: 15, right: 15, top: 25, bottom: 10 })

          Column() {
            // 水泵控制
            this.DeviceControlItem('💦', '滴灌水泵', this.pumpOpen, this.isAutoMode, `当土壤湿度低于 ${this.thresholdSoil}% 时启动`, (val) => this.pumpOpen = val)

            // LED补光控制
            this.DeviceControlItem('☀️', 'LED补光灯', this.ledOpen, this.isAutoMode, `当光照强度低于 ${this.thresholdLight}Lx 时启动`, (val) => this.ledOpen = val)


            this.DeviceControlItem('💨', '通风排气扇', this.fanOpen, this.isAutoMode, `当空气温度高于 ${this.thresholdTemp}℃ 时启动`, (val) => this.fanOpen = val)

            if (this.isAutoMode) {
              Column({ space: 10 }) {
                Text('调整触发阈值').fontSize(14).fontColor('#999').width('100%')
                Row() { Text('土壤湿度下限').fontSize(14); Blank(); Text(`${this.thresholdSoil}%`) }.width('100%')
                Slider({ value: this.thresholdSoil, min: 0, max: 100 }).onChange((v) => this.thresholdSoil = Math.round(v))

                Row() { Text('光照强度下限').fontSize(14); Blank(); Text(`${this.thresholdLight}Lx`) }.width('100%')
                Slider({ value: this.thresholdLight, min: 0, max: 2000 }).onChange((v) => this.thresholdLight = Math.round(v))

                Row() { Text('空气温度上限').fontSize(14); Blank(); Text(`${this.thresholdTemp}℃`) }.width('100%')
                Slider({ value: this.thresholdTemp, min: 0, max: 50 }).onChange((v) => this.thresholdTemp = Math.round(v))
              }.padding(15).backgroundColor('#F9F9F9').borderRadius(12).width('100%')
            }

          }.padding({ left: 15, right: 15, bottom: 40 })

        }.width('100%')
      }
      .width('100%').height('100%').backgroundColor('#F5F7FA')
    }
    .title(this.ghData.name)
    .onReady((ctx) => {
      this.pathStack = ctx.pathStack;
    })
  }
}