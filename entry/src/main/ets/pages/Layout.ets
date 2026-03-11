import { Chat } from "./Chat";
import { Control } from "./Control";
import { Mine } from "./Mine";
import { Monitor } from "./Monitor";

// 跳转页面入口函数
interface TabClass {
  text: string;
  icon: ResourceStr;       // 常规图标
  activeIcon: ResourceStr;  // 激活状态图标
}


@Builder
export function LayoutBuilder() {
  Layout();
}

@ComponentV2
struct Layout {
  @Local currentIndex: number = 0
  pathStack: NavPathStack = new NavPathStack();
  tabData: TabClass[] = [
    {
      text: '控制',
      icon: $r('app.media.control_icon'),
      activeIcon: $r('app.media.control_active_icon')
    },
    {
      text: '监测',
      icon: $r('app.media.monitor_icon'),
      activeIcon: $r('app.media.monitor_active_icon')
    },
    {
      text: '对话',
      icon: $r('app.media.ai_chat_icon'),
      activeIcon: $r('app.media.ai_chat_active_icon')
    },
    {
      text: '我的',
      icon: $r('app.media.mine_icon'),
      activeIcon: $r('app.media.mine_active_icon')
    }
  ]
  //底部导航栏
  @Builder tabBuilder(item: TabClass, index: number){
    Column({space: 5}){
      Image(this.currentIndex === index ? item.activeIcon : item.icon)
        .width(33)

      Text(item.text)
        .fontSize(14)
        .fontColor(this.currentIndex === index ?'#63AAAA':Color.Black)
    }

  }

  build() {
    NavDestination() {
      Tabs({barPosition: BarPosition.End}){
        ForEach(this.tabData,(item: TabClass,index: number)=>{
          TabContent(){
            if(this.currentIndex === 0){
              Control()
            } else if(this.currentIndex === 1){
              Monitor()
            }else if(this.currentIndex === 2){
              Chat()
            }else if(this.currentIndex ===3){
              Mine({ pathStack: this.pathStack })
            }

          }
          .tabBar(this.tabBuilder(item, index))

          .backgroundColor(Color.White)
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
        })
      }
      .animationDuration(0)
      .scrollable(false)
      .onChange((index :number) => {
        this.currentIndex = index
      })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}