//启动页面
@Builder
export function StartBuilder() {
  Start ();
}

@Component
struct Start {
  pathStack: NavPathStack = new NavPathStack();//控制跳转对象
  aboutToAppear(): void {
    setTimeout(()=>{
      this.pathStack.replacePathByName("Layout", null, false)
    },1000)
  }

  build() {
    NavDestination() {
      Stack({alignContent: Alignment.TopEnd}){
        Image($r('app.media.launch_page'))
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
        // Button('跳过')
        //   .backgroundColor(Color.Gray)
        //   .margin(15)
        //   .onClick(()=>{
        //     this.pathStack.replacePathByName("Layout", null, false)
        //   })
      }
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}