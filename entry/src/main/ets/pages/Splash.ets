// 跳转页面入口函数
@Builder
export function StartBuilder() {
  Start ();
}

@Component
struct Start {
  pathStack: NavPathStack = new NavPathStack();//控制跳转对象

  build() {
    NavDestination() {

    }
    .title('启动页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}