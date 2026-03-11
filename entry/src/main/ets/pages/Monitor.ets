@Component
export struct Monitor {
  // --- 模拟数据状态 ---
  @State airTemp: string = '26.5';
  @State airHum: string = '45';
  @State soilHum: string = '32';
  @State lightLux: string = '850';
  @State co2: string = '410';

  // --- 设备控制状态 ---
  // 水泵灌溉控制
  @State isAutoIrrigation: boolean = true; // 是否自动模式
  @State pumpOpen: boolean = false; // 水泵开关
  @State soilHumThreshold: number = 20; // 自动灌溉土壤湿度阈值

  // 光照控制
  @State isAutoLight: boolean = true; // 是否自动光照
  @State ledOpen: boolean = true; // LED开关
  @State lightBrightness: number = 60; // 亮度 0-100


  // 顶部数据卡片构建器
  @Builder DataCard(title: string, value: string, unit: string, iconColor: string) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Circle({ width: 8, height: 8 }).fill(iconColor) // 这里使用了传进来的颜色
        Text(title).fontSize(14).fontColor('#666')
      }.width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 4 }) {
        Text(value).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#333') // 如果你想让数字也变色，可以把这里的 '#333' 也改成 iconColor
        Text(unit).fontSize(12).fontColor('#999').margin({ bottom: 4 })
      }.alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 6, color: '#0A000000', offsetY: 2 })
  }

  build() {
    Scroll() {
      Column({ space: 15 }) {
        // 页面标题
        Row() {
          Text('智慧农业监测中心')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
        }
        .width('100%')
        .padding({ left: 5, top: 10, bottom: 5 })

        //  实时数据网格展示区
        Grid() {
          GridItem() { this.DataCard('空气温度', this.airTemp, '℃', '#FF6B6B') }
          GridItem() { this.DataCard('空气湿度', this.airHum, '%', '#4DABF7') }
          GridItem() { this.DataCard('土壤湿度', this.soilHum, '%', '#8CE200') }
          GridItem() { this.DataCard('光照强度', this.lightLux, 'Lx', '#FCC419') }
          GridItem() { this.DataCard('CO2 浓度', this.co2, 'ppm', '#A9A9A9') }
        }
        .columnsTemplate('1fr 1fr') // 两列等宽
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')

        // 数据视图切换 (预留图表位置)
        Row() {
          Text('实时数据').fontSize(14).fontColor('#00B96B').fontWeight(FontWeight.Medium)
          Text('24H曲线').fontSize(14).fontColor('#999')
          Text('历史均值').fontSize(14).fontColor('#999')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .padding(12)
        .backgroundColor(Color.White)
        .borderRadius(20)
        .margin({ top: 5 })

        // 设备控制中心
        Text('智能控制台')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 10 })

        //智能灌溉模块
        Column({ space: 12 }) {
          Row() {
            Text('💦 智能灌溉').fontSize(16).fontWeight(FontWeight.Medium)
            Blank()
            Text(this.isAutoIrrigation ? '自动模式' : '手动模式')
              .fontSize(14).fontColor('#666')
            Toggle({ type: ToggleType.Switch, isOn: this.isAutoIrrigation })
              .selectedColor('#00B96B')
              .onChange((isOn) => this.isAutoIrrigation = isOn)
          }.width('100%')

          Divider().color('#F0F0F0')

          if (this.isAutoIrrigation) {
            //自动模式：设置阈值
            Row() {
              Text('启动阈值 (土壤湿度低于)').fontSize(14).fontColor('#666')
              Blank()
              Text(`${this.soilHumThreshold}%`).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#00B96B')
            }.width('100%')
            Slider({ value: this.soilHumThreshold, min: 0, max: 100, style: SliderStyle.OutSet })
              .selectedColor('#00B96B')
              .onChange((val) => this.soilHumThreshold = Math.round(val))
          } else {
            //手动模式：控制水泵
            Row() {
              Text('水泵控制').fontSize(14).fontColor('#666')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.pumpOpen })
                .selectedColor('#4DABF7')
                .onChange((isOn) => {
                  this.pumpOpen = isOn;
                  // TODO: 这里向网关发送控制水泵的 MQTT/HTTP 指令
                })
            }.width('100%')
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)

        //智能光照模块
        Column({ space: 12 }) {
          Row() {
            Text('☀️ 补光控制').fontSize(16).fontWeight(FontWeight.Medium)
            Blank()
            Text(this.isAutoLight ? '自动调光' : '手动控制')
              .fontSize(14).fontColor('#666')
            Toggle({ type: ToggleType.Switch, isOn: this.isAutoLight })
              .selectedColor('#00B96B')
              .onChange((isOn) => this.isAutoLight = isOn)
          }.width('100%')

          Divider().color('#F0F0F0')

          if (!this.isAutoLight) {
            // 手动模式控制亮度和开关
            Row() {
              Text('灯光开关').fontSize(14).fontColor('#666')
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.ledOpen })
                .selectedColor('#FCC419')
                .onChange((isOn) => this.ledOpen = isOn)
            }.width('100%')

            Row() {
              Text('亮度调节').fontSize(14).fontColor('#666')
              Blank()
              Text(`${this.lightBrightness}%`).fontSize(14).fontColor('#333')
            }.width('100%').margin({ top: 8 })

            Slider({ value: this.lightBrightness, min: 0, max: 100, style: SliderStyle.OutSet })
              .selectedColor('#FCC419')
              .onChange((val) => {
                this.lightBrightness = Math.round(val)
                // TODO: 亮度拖动结束后，发送控制指令给硬件
              })
          } else {
            Text('系统正根据环境光照自动调节补光亮度')
              .fontSize(13)
              .fontColor('#999')
              .width('100%')
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ bottom: 30 })

      }
      .width('100%')
      .padding({ left: 15, right: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
  }
}