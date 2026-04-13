import { DatabaseManager } from '../data/DatabaseManager';
import { GreenhouseModel } from '../model/GreenhouseModel';
import { promptAction } from '@kit.ArkUI';

@CustomDialog
struct GreenhouseDialog {
  controller?: CustomDialogController
  @Link ghData: GreenhouseModel;
  confirmAction: () => void = () => {}

  build() {
    Column({ space: 15 }) {
      Text(this.ghData.id ? '编辑大棚' : '新增大棚').fontSize(20).fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '大棚名称 (必填)', text: this.ghData.name })
        .onChange((val) => this.ghData.name = val)
      TextInput({ placeholder: '网关设备ID (必填)', text: this.ghData.deviceId })
        .onChange((val) => this.ghData.deviceId = val)
      TextInput({ placeholder: '种植作物 (可选)', text: this.ghData.crop })
        .onChange((val) => this.ghData.crop = val)
      //阶段选择
      Row() {
        Text('生长阶段(可选)：').fontSize(14).fontColor('#666')
        Select([{value:'未设置'}, {value:'育苗'}, {value:'生长'}, {value:'开花'}, {value:'结果'}])
          .selected(this.ghData.stage === -1 ? 0 : this.ghData.stage + 1)
          .value(['未设置', '育苗', '生长', '开花', '结果'][this.ghData.stage === -1 ? 0 : this.ghData.stage + 1])
          .onSelect((index) => {
            this.ghData.stage = index - 1;
          })
      }.width('100%').justifyContent(FlexAlign.Start)


      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor('#EEE').fontColor('#666')
          .onClick(() => this.controller?.close())
        //保存逻辑判断
        Button('保存').layoutWeight(1).backgroundColor('#00B96B')
          .onClick(() => {
            if (!this.ghData.name || this.ghData.name.trim() === '') {
              promptAction.showToast({ message: '请输入大棚名称！' });
              return;
            }
            if (!this.ghData.deviceId || this.ghData.deviceId.trim() === '') {
              promptAction.showToast({ message: '请输入网关设备ID' });
              return;
            }
            this.confirmAction();
            this.controller?.close();
          })
      }.margin({ top: 10 })

    }.padding(20).backgroundColor(Color.White).borderRadius(16)
  }
}

@Preview
@Component
export struct Monitor {
  pathStack?: NavPathStack;
  @State ghList: GreenhouseModel[] = [];

  @State currentGh: GreenhouseModel = new GreenhouseModel();

  dialogController: CustomDialogController = new CustomDialogController({
    builder: GreenhouseDialog({
      ghData: $currentGh,
      confirmAction: async () => {
        if (this.currentGh.id) {
          await DatabaseManager.updateGreenhouse(this.currentGh);
        } else {
          await DatabaseManager.insertGreenhouse(this.currentGh);
        }
        this.loadData();
      }
    }),
    alignment: DialogAlignment.Center
  })
  //加载列表数据
  aboutToAppear() {
    this.loadData();
  }

  async loadData() {
    this.ghList = await DatabaseManager.getGreenhouseList();
  }


  @Builder
  GhMenuBuilder(item: GreenhouseModel) {
    Menu() {
      MenuItem({ content: '编辑信息' })
        .onClick(() => {
          let editGh = new GreenhouseModel();
          editGh.id = item.id;
          editGh.name = item.name;
          editGh.deviceId = item.deviceId;
          editGh.crop = item.crop;
          editGh.stage = item.stage;

          this.currentGh = editGh;
          this.dialogController.open();
        })

      MenuItem({ content: '删除大棚' })
        .onClick(async () => {
          if (item.id) {
            await DatabaseManager.deleteGreenhouse(item.id);
            this.loadData();
          }
        })
    }
  }

  @Builder GhCard(item: GreenhouseModel) {
    Column() {
      Image($r('app.media.app_icon'))
        .width('100%').height(100).objectFit(ImageFit.Cover)
        .backgroundColor('#E8F5E9')

      Column({ space: 6 }) {
        Row() {
          Text(item.name)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .maxLines(1).textOverflow({overflow: TextOverflow.Ellipsis})
            .layoutWeight(1)
          Text('⋮')
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#999')
            .padding({left: 10, right: 5, bottom: 5})
            .bindMenu(this.GhMenuBuilder(item))
        }.width('100%').alignItems(VerticalAlign.Center)

        Text(`作物: ${item.crop || '未设置'}`).fontSize(12).fontColor('#666')

        if (item.stage !== undefined && item.stage >= 0) {
          Row() {
            Text(['🌱 育苗期', '🌿 生长期', '🌸 开花期', '🍅 结果期'][item.stage])
              .fontSize(12).fontColor('#00B96B').backgroundColor('#E6F8F0')
              .padding({left:6, right:6, top:2, bottom:2}).borderRadius(8)
          }.width('100%')
        } else {
          Row().height(18)
        }
      }.padding({left: 12, right: 12, top: 8, bottom: 12}).alignItems(HorizontalAlign.Start).width('100%')
    }
    .width('100%').backgroundColor(Color.White).borderRadius(12).clip(true)
    .shadow({ radius: 8, color: '#0A000000', offsetY: 4 })
    .onClick(() => {
      if(this.pathStack) {
        this.pathStack.pushPathByName('MonitorDetail', item);
      }
    })
    .bindContextMenu(this.GhMenuBuilder(item), ResponseType.LongPress)
  }


  //顶部背景区
  @Builder HeaderDashboard() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column()
        .width('100%')
        .height(220)
        .backgroundColor('#28C76F')
        .borderRadius({ bottomLeft: 30, bottomRight: 30 })
        .shadow({ radius: 10, color: '#2000B96B', offsetY: 4 })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Row() {
        Column({ space: 8 }) {
          Text('大棚管理')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .letterSpacing(1)

          Text(`当前已接入 ${this.ghList.length} 个智能大棚节点`)
            .fontSize(14)
            .fontColor('rgba(255, 255, 255, 0.85)')


        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Blank()
        Blank()


        Image($r('app.media.greenhouse2'))
          .width(140)
          .height(120)

         // .opacity(0.2)
      }
      .width('100%')
      .padding({ left: 25, right: 25, bottom: 100 })
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 全局透明水印底图
      Image($r('app.media.greenhouse'))
        .width('120%')
        .opacity(0.05)
        .position({ x: '-10%', y: '50%' })

      Column() {
        // 顶部渐变看板
        this.HeaderDashboard()

        if (this.ghList.length === 0) {
          // 为空时的状态页
          Column({ space: 15 }) {
            Image($r('app.media.app_icon'))
              .opacity(0.2)
              .width(130)
              .height(130)

            Text('暂无大棚数据\n点击右下角立刻添加')
              .fontSize(15)
              .fontColor('#999')
              .textAlign(TextAlign.Center)
              .lineHeight(24)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .margin({ top: -50 })

        } else {
          // 列表区
          Grid() {
            ForEach(this.ghList, (item: GreenhouseModel) => {
              GridItem() { this.GhCard(item) }
            })
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(15).rowsGap(15)
          .padding({ left: 15, right: 15, bottom: 100 })
          .width('100%').layoutWeight(1)
          .margin({ top: -45 })
          .scrollBar(BarState.Off)
        }
      }.width('100%').height('100%')

      // 悬浮添加按钮
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.add_icon'))
          .width(28).height(28).fillColor(Color.White)
      }
      .width(60).height(60).backgroundColor('#00B96B')
      .shadow({ radius: 10, color: '#5000B96B', offsetY: 6 })
      .margin({ right: 20, bottom: 20 })
      .onClick(() => {
        this.currentGh = new GreenhouseModel();
        this.dialogController.open();
      })
    }.width('100%').height('100%').backgroundColor('#F5F7FA')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
  }
}