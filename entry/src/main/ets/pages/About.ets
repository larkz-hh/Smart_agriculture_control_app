@Builder
export function AboutBuilder() {
  About()
}
@Preview
@Component
export struct About {
  pathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Image($r('app.media.app_icon'))
          .width(90)
          .height(90)
          .borderRadius(20)
          .margin({ top: 80, bottom: 10 })
          .shadow({ radius: 10, color: '#1A000000', offsetY: 4 })

        Text('耘智')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text('智慧农业控制系统')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text('Version 1.0.0')
          .fontSize(14)
          .fontColor('#999')

        Blank()

        // Text('Copyright © 2026')
        //   .fontSize(12)
        //   .fontColor('#CCC')
        //   .margin({ bottom: 40 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F6FB')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title('关于我们')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}