import { DatabaseManager } from '../data/DatabaseManager';
import { RecordGroup } from '../model/RecordModel';
export class RecordDetailParam {
  id: number;
  name: string;

  constructor(id: number, name: string) {
    this.id = id;
    this.name = name;
  }
}
@CustomDialog
struct CreateGroupDialog {
  controller: CustomDialogController;
  cancel: () => void = () => {};
  confirm: (name: string) => void = () => {};
  @State inputName: string = '';

  build() {
    Column({ space: 20 }) {
      Text('新建种植分组').fontSize(20).fontWeight(FontWeight.Bold).margin({top: 10})
      TextInput({ placeholder: '分组名' })
        .height(50).backgroundColor('#F5F5F5')
        .onChange((val) => this.inputName = val)
      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor('#E0E0E0').fontColor('#666')
          .onClick(() => { this.controller.close(); this.cancel(); })
        Button('确定').layoutWeight(1).backgroundColor('#00B96B')
          .onClick(() => {
            if(this.inputName.trim()){
              this.confirm(this.inputName);
              this.controller.close();
            }
          })
      }.width('100%')
    }.padding(24).backgroundColor(Color.White).borderRadius(16)
  }
}

@Builder
export function RecordListBuilder() { RecordList() }

@Component
export struct RecordList {
  pathStack: NavPathStack = new NavPathStack();
  @State groupList: RecordGroup[] = [];

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CreateGroupDialog({
      cancel: () => {},
      confirm: async (name) => {
        await DatabaseManager.insertRecordGroup(name);
        this.loadGroups();
      }
    }),
    alignment: DialogAlignment.Center
  })

  aboutToAppear() {
    this.loadGroups();
  }

  async loadGroups() {
    this.groupList = await DatabaseManager.getRecordGroups();
  }

  formatDate(ts: number) {
    let d = new Date(ts);
    return `${d.getFullYear()}-${(d.getMonth()+1).toString().padStart(2,'0')}-${d.getDate().toString().padStart(2,'0')}`;
  }
  @Builder DeleteGroupMenu(groupId: number) {
    Menu() {
      MenuItem({ content: '删除该分组' })
        .onClick(async () => {
          await DatabaseManager.deleteRecordGroup(groupId);
          this.loadGroups();
        })
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.groupList.length === 0) {
          Column() { Text('暂无种植分组，点击右下角添加').fontColor('#999').margin({top: 100}) }.width('100%').height('100%')
        } else {
          List({ space: 15 }) {
            ForEach(this.groupList, (item: RecordGroup) => {
              ListItem() {
                Row() {
                  Image($r('app.media.plants_icon')).width(40).height(40).margin({right: 15})
                  Column({space: 5}) {
                    Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
                    Text(`最后更新: ${this.formatDate(item.updateTime)}`).fontSize(12).fontColor('#999')
                  }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                  Image($r('sys.media.ohos_ic_public_arrow_right')).width(20).fillColor('#CCC')
                }
                .width('100%').padding(20).backgroundColor(Color.White).borderRadius(16)
                .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
              }
              .bindContextMenu(this.DeleteGroupMenu(item.id), ResponseType.LongPress)
              .onClick(() => {
                let param = new RecordDetailParam(item.id, item.name);
                this.pathStack.pushPathByName('RecordDetail', param);
              })
            })
          }.width('100%').height('100%').padding(15)
        }

        // 悬浮添加按钮
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('+').fontSize(30).fontColor(Color.White).margin({bottom: 4})
        }
        .width(60).height(60).backgroundColor('#00B96B')
        .shadow({ radius: 8, color: '#4000B96B', offsetY: 4 })
        .margin({ right: 20, bottom: 30 })
        .onClick(() => { this.dialogController.open(); })
      }
      .width('100%').height('100%').backgroundColor('#F5F7FA')
    }
    .title('种植记录分组')
    .onReady((context) => { this.pathStack = context.pathStack; })
    .onShown(() => { this.loadGroups(); }) // 返回时刷新列表时间
  }
}