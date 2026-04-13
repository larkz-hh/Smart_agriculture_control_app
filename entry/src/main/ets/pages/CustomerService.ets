import { promptAction } from '@kit.ArkUI';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { call } from '@kit.TelephonyKit';

@Builder
export function CustomerServiceBuilder() {
  CustomerService()
}
@Preview
@Component
export struct CustomerService {
  pathStack: NavPathStack = new NavPathStack();
  @State servicePhone: string = '123-456-7890';

  // 复制号码到剪贴板
  copyToPasteboard() {
    let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.servicePhone);
    let systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData).then(() => {
      promptAction.showToast({ message: '电话号码已复制' });
    }).catch((err: BusinessError) => {
      promptAction.showToast({ message: '复制失败' });
    });
  }

  // 拉起拨号盘并填入号码
  makePhoneCall() {
    call.makeCall(this.servicePhone).catch((err: BusinessError) => {
      console.error(`拨打电话失败: ${err.message}`);
      promptAction.showToast({ message: '无法拉起系统拨号盘' });
    });
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Image($r('app.media.service'))
          .width(70)
          .height(70)
          .margin({ top: 60 })

        Text('联系客服')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        // 白色卡片区域
        Column({ space: 15 }) {

          Text(this.servicePhone)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#63AAAA')
            .onClick(() => {
              this.makePhoneCall();
            })

          Row({ space: 15 }) {
            Text('点击号码拨打')
              .fontSize(13)
              .fontColor('#999')

            Text('|')
              .fontSize(12)
              .fontColor('#E0E0E0')

            Text('点击复制')
              .fontSize(13)
              .fontColor('#63AAAA')
              .onClick(() => {
                this.copyToPasteboard();
              })
          }
        }
        .width('85%')
        .padding(30)
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 15, color: '#08000000', offsetY: 6 })

        Blank()

        Text('欢迎随时联系我们，我们将竭诚为您服务')
          .fontSize(12)
          .fontColor('#999')
          .margin({ bottom: 40 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F6FB')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .title('客服帮助')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}