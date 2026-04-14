import { promptAction } from '@kit.ArkUI';

@Builder
export function SettingsBuilder() {
  Settings()
}
@Preview
@Component
export struct Settings {
  pathStack: NavPathStack = new NavPathStack();

  @StorageLink('isAlertEnabled') isAlertEnabled: boolean = true;

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('消息预警通知').fontSize(16).fontColor('#333').fontWeight(FontWeight.Medium)
          Blank()
          Toggle({ type: ToggleType.Switch, isOn: this.isAlertEnabled })
            .selectedColor('#00B96B')
            .onChange((isOn: boolean) => {
              this.isAlertEnabled = isOn;
              if (isOn) {
                promptAction.showToast({ message: '预警功能已开启' });
              } else {
                promptAction.showToast({ message: '预警功能已关闭' });
              }
            })
        }
        .width('100%')
        .padding(15)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ top: 15 })

        Text('关闭后将不再接收设备数据异常的系统通知和消息记录。')
          .fontSize(12)
          .fontColor('#999')
          .width('100%')
          .padding({ left: 5, top: 10 })

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F7FA')
      .padding({ left: 15, right: 15 })
    }
    .title('系统设置')
    .onReady((ctx) => {
      this.pathStack = ctx.pathStack;
    })
  }
}