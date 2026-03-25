import { promptAction } from '@kit.ArkUI';
import { AiService, PlantInfo } from '../services/ai/AIService';

@Builder
export function PlantsBuilder(name: string, param: Object) {
  Plants()
}

@Component
export struct Plants {
  pathStack: NavPathStack = new NavPathStack();

  @State plantName: string = '';
  @State growthStage: string = '';

  @State isLoading: boolean = false;
  @State resultInfo: PlantInfo | null = null;

  async handleSearch() {
    if (!this.plantName.trim() || !this.growthStage.trim()) {
      promptAction.showToast({ message: '请输入完整的植物名称和生长时期' });
      return;
    }

    this.isLoading = true;
    this.resultInfo = null; // 清空上次的结果
    let res = await AiService.getPlantInfo(this.plantName, this.growthStage);

    if (res) {
      this.resultInfo = res;
    } else {
      promptAction.showToast({ message: '查询失败或AI响应超时，请重试' });
    }
    this.isLoading = false;
  }

  //构建结果列表中单项
  @Builder ResultItem(title: string, value: string, iconColor: string) {
    Column() {
      Row({ space: 8 }) {
        Circle({ width: 10, height: 10 }).fill(iconColor)
        Text(title).fontSize(14).fontColor('#666')
      }.width('100%').margin({ bottom: 8 })

      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333')
        .width('100%')
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#F9F9F9')
    .borderRadius(12)
  }

  build() {
    NavDestination() {
      Column() {
        Column({ space: 15 }) {
          Text('告诉我们你种了什么，AI专家为你提供最佳环境参数')
            .fontSize(14).fontColor('#999').margin({ bottom: 5, top: 10 })

          TextInput({ placeholder: '例如：番茄、草莓、水稻...', text: this.plantName })
            .height(50).backgroundColor('#F5F5F5')
            .onChange((val) => this.plantName = val)

          TextInput({ placeholder: '例如：发芽期、幼苗期、开花期、结果期...', text: this.growthStage })
            .height(50).backgroundColor('#F5F5F5')
            .onChange((val) => this.growthStage = val)

          Button('AI 智能分析查询')
            .width('100%')
            .height(45)
            .backgroundColor('#00B96B')
            .margin({ top: 10 })
            .onClick(() => {
              if (!this.isLoading) this.handleSearch();
            })
        }
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .width('92%')
        .margin({ top: 20 })
        .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })

        //状态与结果
        if (this.isLoading) {
          Column({ space: 15 }) {
            LoadingProgress().width(40).height(40).color('#00B96B')
            Text('农业大脑正在分析最佳参数...').fontSize(14).fontColor('#999')
          }.margin({ top: 60 })

        } else if (this.resultInfo) {
          // 渲染AI返回的数据列表
          Scroll() {
            Column({ space: 12 }) {
              Text(`【${this.plantName}】在【${this.growthStage}】的适宜环境：`)
                .fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 5 })

              this.ResultItem('光照要求', this.resultInfo.light, '#FCC419')
              this.ResultItem('土壤适宜温度', this.resultInfo.soilTemp, '#8CE200')
              this.ResultItem('土壤适宜湿度', this.resultInfo.soilMoisture, '#4DABF7')
              this.ResultItem('空气适宜温度', this.resultInfo.airTemp, '#FF6B6B')
              this.ResultItem('空气适宜湿度', this.resultInfo.airMoisture, '#A9A9A9')
              this.ResultItem('二氧化碳适宜浓度',this.resultInfo.carbonDioxide,'#000000')
            }
            .padding(20)
          }.layoutWeight(1)
          .margin({ top: 10 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')
      .alignItems(HorizontalAlign.Center)
    }
    .title('植物百科')
    .onReady((context) => {
      this.pathStack = context.pathStack;
    })
  }
}