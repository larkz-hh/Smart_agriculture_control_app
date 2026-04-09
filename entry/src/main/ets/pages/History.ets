import { DatabaseManager } from "../data/DatabaseManager";
import emitter from '@ohos.events.emitter';
import { SessionItem } from "../model/MessageModel";

@Builder
export function HistoryBuilder(name: string, param: Object) {
  History()
}

@Component
export struct History {
  pathStack: NavPathStack = new NavPathStack();

  @State sessionList: SessionItem[] = [];

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.sessionList = await DatabaseManager.getSessionList();
  }

  //时间格式化
  formatTime(ts: number): string {
    let d = new Date(ts);
    return `${d.getMonth()+1}-${d.getDate()} ${d.getHours()}:${d.getMinutes()}`;
  }

  //长按菜单
  @Builder DeleteMenu(sessionId: number) {
    Menu() {
      MenuItem({ content: '删除该会话' })
        .onClick(async () => {
          await DatabaseManager.deleteSession(sessionId);
          this.loadData();
          emitter.emit({ eventId: 2001 }, {
            data: { deletedId: sessionId }
          });
        })
    }
  }

  build() {
    NavDestination() {
      if (this.sessionList.length === 0) {
        Column() {
          Text('暂无历史对话').fontSize(14).fontColor('#999').margin({ top: 100 })
        }.width('100%').height('100%')
      } else {
        List() {
          ForEach(this.sessionList, (item: SessionItem) => {
            ListItem() {
              Row() {
                Text(item.title)
                  .fontSize(16)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)

                Text(this.formatTime(item.timestamp))
                  .fontSize(12)
                  .fontColor('#999')
                  .margin({ left: 10 })
              }
              .width('100%')
              .padding(20)
              .backgroundColor(Color.White)
              .border({ width: { bottom: 1 }, color: '#F0F0F0' })
            }
            //绑定长按删除菜单
            .bindContextMenu(this.DeleteMenu(item.id), ResponseType.LongPress)
            .onClick(() => {
              //选中后，把自己销毁，并把选中的ID作为result传给Chat
              this.pathStack.pop(item.id);
            })
          })
        }
        .width('100%')
        .height('100%')
      }
    }
    .title('历史对话记录')
    .backgroundColor('#F5F7FA')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}