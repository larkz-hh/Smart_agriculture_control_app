import { promptAction } from '@kit.ArkUI';

@Builder
export function AddDeviceBuilder(name: string, param: Object) {
  AddDevice()
}

@Preview
@Component
export struct AddDevice {
  pathStack: NavPathStack = new NavPathStack();

  // 绑定用户输入的设备ID
  @State inputDeviceId: string = '';

  //处理绑定逻辑
  handleBindDevice() {
    if (!this.inputDeviceId.trim()) {
      promptAction.showToast({ message: '设备ID不能为空' });
      return;
    }

    //用户输入的DeviceID存入全局缓存
    AppStorage.setOrCreate('currentDeviceId', this.inputDeviceId.trim());

    promptAction.showToast({ message: '设备添加成功！' });

    //添加成功后，返回上一页
    this.pathStack.pop();
  }

  build() {
    NavDestination() {
      Column({ space: 25 }) {
        // 顶部图标
        Image($r('app.media.device_add_icon'))
          .width(80)
          .height(80)
          .margin({ top: 60, bottom: 20 })

        Text('绑定新设备')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text('请输入设备外包装或背面的设备标识码 (Device ID)')
          .fontSize(14)
          .fontColor('#999')
          .textAlign(TextAlign.Center)
          .padding({ left: 20, right: 20 })


        TextInput({ placeholder: '例如：agri_hub_001', text: this.inputDeviceId })
          .height(55)
          .width('90%')
          .backgroundColor('#F5F7FA')
          .borderRadius(12)
          .onChange((value: string) => {
            this.inputDeviceId = value;
          })


        Button('立即绑定')
          .width('90%')
          .height(50)
          .backgroundColor('#00B96B')
          .margin({ top: 20 })

          .onClick(() => this.handleBindDevice())

      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
    }
    .title('添加设备')
    .backgroundColor('#F5F7FA')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}