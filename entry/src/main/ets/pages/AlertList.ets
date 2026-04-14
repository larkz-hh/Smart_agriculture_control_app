import { DatabaseManager } from '../data/DatabaseManager';
import { AlertMessageModel } from '../model/AlertMessageModel';
import { promptAction } from '@kit.ArkUI';

@Builder
export function AlertListBuilder() {
  AlertList()
}

@Component
export struct AlertList {
  pathStack: NavPathStack = new NavPathStack();
  @State alertList: AlertMessageModel[] = [];

  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.alertList = await DatabaseManager.getAlertList();

    //进入页面，把所有的未读消息变成已读
    await DatabaseManager.markAllAlertsAsRead();
    // 清除首页的红点状态
    AppStorage.setOrCreate('hasNewAlert', false);
  }

  formatTime(ts: number) {
    let date = new Date(ts);
    return `${date.getMonth()+1}-${date.getDate()} ${date.getHours()}:${date.getMinutes().toString().padStart(2,'0')}`;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('消息清空').fontColor('#FF4D4F').fontSize(14)
            .onClick(async () => {
              await DatabaseManager.clearAllAlerts();
              this.loadData();
              promptAction.showToast({ message: '已清空所有预警' });
            })
        }.width('100%').justifyContent(FlexAlign.End).padding(15)

        if (this.alertList.length === 0) {
          Text('暂无预警消息').fontColor('#999').margin({ top: 100 })
        } else {
          List({ space: 10 }) {
            ForEach(this.alertList, (item: AlertMessageModel) => {
              ListItem() {
                Column({ space: 8 }) {
                  Row() {
                    Text(`[${item.ghName}] 触发预警`).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FF4D4F')// 大棚名称
                    Blank()
                    Text(this.formatTime(item.timestamp)).fontSize(12).fontColor('#999')
                  }.width('100%')

                  Text(item.content).fontSize(14).fontColor('#333').lineHeight(20).width('100%')
                }
                .padding(15).backgroundColor(Color.White).borderRadius(12)
                .shadow({ radius: 5, color: '#0A000000', offsetY: 2 })
                .width('92%').margin({ left: '4%' })
              }
              // 左滑删除
              .swipeAction({ end: this.DeleteButton(item) })
            })
          }.width('100%').layoutWeight(1)
        }
      }.width('100%').height('100%').backgroundColor('#F5F7FA')
    }
    .title('预警消息')
    .onReady((ctx) => { this.pathStack = ctx.pathStack; })
    //页面退出时，作为双保险再清一次红点
    .onDisAppear(() => {
      AppStorage.setOrCreate('hasNewAlert', false);
    })
  }
  //左滑删除功能
  @Builder DeleteButton(item: AlertMessageModel) {
    Row() {
      Text('删除').fontColor(Color.White).fontSize(14)
    }
    .width(70).height('100%').backgroundColor('#FF4D4F')
    .justifyContent(FlexAlign.Center)
    .onClick(async () => {
      await DatabaseManager.deleteAlert(item.id);// 删除数据库记录
      this.loadData();// 刷新列表
    })
  }
}