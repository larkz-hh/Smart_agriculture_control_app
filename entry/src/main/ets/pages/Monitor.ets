@Component
export struct Monitor {
  pathStack?: NavPathStack;

  // 设备在线状态，模拟
  @State isDeviceConnected: boolean = false;

  // 模拟数据状态
  @State airTemp: string = '26.5';
  @State airHum: string = '45';
  @State soilHum: string = '32';
  @State lightLux: string = '850';
  @State co2: string = '410';

  // 设备控制状态
  @State isAutoIrrigation: boolean = true;
  @State pumpOpen: boolean = false;
  @State soilHumThreshold: number = 20;

  @State isAutoLight: boolean = true;
  @State ledOpen: boolean = true;
  @State lightBrightness: number = 60;

  //顶部数据卡片构建器
  @Builder DataCard(title: string, value: string, unit: string, iconColor: string) {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Circle({ width: 8, height: 8 }).fill(iconColor)
        Text(title).fontSize(14).fontColor('#666')
      }.width('100%').alignItems(VerticalAlign.Center)

      Row({ space: 4 }) {
        //如果设备掉线，显示 "--"，否则显示真实数据
        Text(this.isDeviceConnected ? value : '--')
          .fontSize(28).fontWeight(FontWeight.Bold)
          .fontColor(this.isDeviceConnected ? '#333' : '#CCC') //断线时数字变灰
        Text(unit).fontSize(12).fontColor('#999').margin({ bottom: 4 })
      }.alignItems(VerticalAlign.Bottom)
    }
    .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)
    .alignItems(HorizontalAlign.Start).shadow({ radius: 6, color: '#0A000000', offsetY: 2 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 页面标题与状态栏
        Row() {
          Text('智慧农业监测中心')
            .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1A1A1A')
          Blank()
          // 🌟 状态指示灯（真实项目中这里不需要点击，这里加 onClick 是为了方便你演示）
          Row({space: 4}) {
            Circle({ width: 8, height: 8 }).fill(this.isDeviceConnected ? '#00B96B' : '#FF4D4F')
            Text(this.isDeviceConnected ? '设备在线' : '设备离线')
              .fontSize(12).fontColor(this.isDeviceConnected ? '#00B96B' : '#FF4D4F')
          }
          .padding({left: 8, right: 8, top: 4, bottom: 4})
          .backgroundColor(this.isDeviceConnected ? '#E6F8F0' : '#FFEDED')
          .borderRadius(12)
          .onClick(() => {
            // TODO: 仅供毕设答辩演示用！点击切换在线/离线状态
            this.isDeviceConnected = !this.isDeviceConnected;
          })
        }
        .width('100%').padding({ left: 15, right: 15, top: 15, bottom: 10 })

        // 提示条
        if (!this.isDeviceConnected) {
          Text('⚠️ 当前未连接到农业网关，无法获取数据与控制设备')
            .width('100%').backgroundColor('#FFFBE6').fontColor('#FAAD14')
            .fontSize(12).padding(10).textAlign(TextAlign.Center)
        }

        Scroll() {
          Column({ space: 15 }) {
            //  实时数据网格展示区
            Grid() {
              GridItem() { this.DataCard('空气温度', this.airTemp, '℃', '#FF6B6B') }
              GridItem() { this.DataCard('空气湿度', this.airHum, '%', '#4DABF7') }
              GridItem() { this.DataCard('土壤湿度', this.soilHum, '%', '#8CE200') }
              GridItem() { this.DataCard('光照强度', this.lightLux, 'Lx', '#FCC419') }
              GridItem() { this.DataCard('CO2 浓度', this.co2, 'ppm', '#A9A9A9') }
            }
            .columnsTemplate('1fr 1fr').columnsGap(12).rowsGap(12).width('100%')

            Row() {
              Text('实时数据').fontSize(14).fontColor('#00B96B').fontWeight(FontWeight.Medium)
              Text('24H曲线').fontSize(14).fontColor('#999')
              Text('历史均值').fontSize(14).fontColor('#999')
            }
            .width('100%').justifyContent(FlexAlign.SpaceAround).padding(12)
            .backgroundColor(Color.White).borderRadius(20).margin({ top: 5 })

            Text('智能控制台').fontSize(18).fontWeight(FontWeight.Bold).width('100%').margin({ top: 10 })

            // 通过 opacity 控制视觉置灰
            Column({ space: 15 }) {
              // 智能灌溉模块
              Column({ space: 12 }) {
                Row() {
                  Text('💦 智能灌溉').fontSize(16).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.isAutoIrrigation ? '自动模式' : '手动模式').fontSize(14).fontColor('#666')
                  Toggle({ type: ToggleType.Switch, isOn: this.isAutoIrrigation })
                    .selectedColor('#00B96B')
                    .enabled(this.isDeviceConnected) //断网时不可点
                    .onChange((isOn) => this.isAutoIrrigation = isOn)
                }.width('100%')

                Divider().color('#F0F0F0')

                if (this.isAutoIrrigation) {
                  Row() {
                    Text('启动阈值 (土壤湿度低于)').fontSize(14).fontColor('#666')
                    Blank()
                    Text(`${this.soilHumThreshold}%`).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#00B96B')
                  }.width('100%')
                  Slider({ value: this.soilHumThreshold, min: 0, max: 100, style: SliderStyle.OutSet })
                    .selectedColor('#00B96B')
                    .enabled(this.isDeviceConnected) //断网时不可拖动
                    .onChange((val) => this.soilHumThreshold = Math.round(val))
                } else {
                  Row() {
                    Text('水泵控制').fontSize(14).fontColor('#666')
                    Blank()
                    Toggle({ type: ToggleType.Switch, isOn: this.pumpOpen })
                      .selectedColor('#4DABF7')
                      .enabled(this.isDeviceConnected) // 断网时不可点
                      .onChange((isOn) => this.pumpOpen = isOn)
                  }.width('100%')
                }
              }
              .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12)

              //智能光照模块
              Column({ space: 12 }) {
                Row() {
                  Text('☀️ 补光控制').fontSize(16).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(this.isAutoLight ? '自动调光' : '手动控制').fontSize(14).fontColor('#666')
                  Toggle({ type: ToggleType.Switch, isOn: this.isAutoLight })
                    .selectedColor('#00B96B')
                    .enabled(this.isDeviceConnected) //断网时不可点
                    .onChange((isOn) => this.isAutoLight = isOn)
                }.width('100%')

                Divider().color('#F0F0F0')

                if (!this.isAutoLight) {
                  Row() {
                    Text('灯光开关').fontSize(14).fontColor('#666')
                    Blank()
                    Toggle({ type: ToggleType.Switch, isOn: this.ledOpen })
                      .selectedColor('#FCC419')
                      .enabled(this.isDeviceConnected) //断网时不可点
                      .onChange((isOn) => this.ledOpen = isOn)
                  }.width('100%')

                  Row() {
                    Text('亮度调节').fontSize(14).fontColor('#666')
                    Blank()
                    Text(`${this.lightBrightness}%`).fontSize(14).fontColor('#333')
                  }.width('100%').margin({ top: 8 })

                  Slider({ value: this.lightBrightness, min: 0, max: 100, style: SliderStyle.OutSet })
                    .selectedColor('#FCC419')
                    .enabled(this.isDeviceConnected) //断网时不可拖动
                    .onChange((val) => this.lightBrightness = Math.round(val))
                } else {
                  Text('系统正根据环境光照自动调节补光亮度')
                    .fontSize(13).fontColor('#999').width('100%')
                }
              }
              .width('100%').padding(16).backgroundColor(Color.White).borderRadius(12).margin({ bottom: 80 }) //底部留点空间给悬浮按钮
            }
            .opacity(this.isDeviceConnected ? 1 : 0.5) //整个控制区断网时变半透明
            .animation({ duration: 300 })

          }
          .width('100%').padding({ left: 15, right: 15 })
        }.layoutWeight(1)
      }
      .width('100%').height('100%')

      //添加设备
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.device_add_icon'))
          .width(28).height(28).fillColor(Color.White)
      }
      .width(60).height(60)
      .backgroundColor('#00B96B')
      .shadow({ radius: 8, color: '#4000B96B', offsetY: 4 }) //绿色的发光阴影
      .margin({ right: 20, bottom: 30 }) //固定在右下角
      .onClick(() => {
        //点击跳转到添加设备/配网页面
        if (this.pathStack) {
          this.pathStack.pushPathByName('AddDevice', null);
        } else {
          console.info('路由栈不存在，无法跳转');
        }
      })

    }
    .width('100%').height('100%').backgroundColor('#F5F7FA')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
  }
}