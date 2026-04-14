import { DatabaseManager } from "../data/DatabaseManager";
import { Chat } from "./Chat";
import { Home } from "./Home";
import { Mine } from "./Mine";
import { Monitor } from "./Monitor";
import emitter from '@ohos.events.emitter';
import { AlertService } from "../services/alert/AlertService.";
import { common } from '@kit.AbilityKit';

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
  aboutToAppear(): void {
    PersistentStorage.persistProp('isAlertEnabled', true);
    DatabaseManager.init(getContext(this)).then(() => {
      AlertService.startPolling();
      AlertService.requestNotificationPermission(getContext(this) as common.UIAbilityContext);
    });
    emitter.on({ eventId: 1001 }, () => {
      this.currentIndex = 2;
    });
  }
  tabData: TabClass[] = [
    {
      text: '首页',
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
              Home({ pathStack: this.pathStack })
            } else if(this.currentIndex === 1){
              Monitor({ pathStack: this.pathStack })
            }else if(this.currentIndex === 2){
              Chat({ pathStack: this.pathStack })
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