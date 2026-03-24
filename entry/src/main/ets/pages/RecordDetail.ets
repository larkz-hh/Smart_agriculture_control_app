import { DatabaseManager } from '../data/DatabaseManager';
import { PlantRecord } from '../model/RecordModel';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import util from '@ohos.util';
import { promptAction } from '@kit.ArkUI';

// 复制系统临时图片到App沙箱，防止重启后权限丢失变白块！
async function copyImageToSandbox(context: common.UIAbilityContext, uri: string): Promise<string> {
  try {
    let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    let fileName = util.generateRandomUUID(true) + '.jpg';
    let sandboxPath = context.filesDir + '/' + fileName;
    fileIo.copyFileSync(file.fd, sandboxPath);
    fileIo.closeSync(file.fd);
    return 'file://' + sandboxPath;
  } catch (e) {
    console.error('拷贝图片到沙箱失败', e);
    return uri; // 失败退回原uri
  }
}

@CustomDialog
struct CreateRecordDialog {
  controller: CustomDialogController;
  groupId: number = 0;
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  onSaved: () => void = () => {};

  @State selectedUri: string = '';
  @State inputDesc: string = '';

  async takePhoto() {
    try {
      let result = await cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.PHOTO], { cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK });
      if (result && result.resultUri) {
        this.selectedUri = await copyImageToSandbox(this.context, result.resultUri);
      }
    } catch (err) {
      console.error('拍照失败', JSON.stringify(err));
    }

  }

  async pickPhoto() {
    try {
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let result = await photoPicker.select({ MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE, maxSelectNumber: 1 });
      if (result && result.photoUris.length > 0) {
        this.selectedUri = await copyImageToSandbox(this.context, result.photoUris[0]);
      }
    } catch (err) {
      console.error('选择照片失败', JSON.stringify(err));
    }
  }

  showActionSheet() {
    ActionSheet.show({
      title: '选择图片',
      message: '拍照或从相册选择',
      autoCancel: true,
      alignment: DialogAlignment.Bottom,
      sheets: [
        { title: '拍照', action: () => this.takePhoto() },
        { title: '从相册选择', action: () => this.pickPhoto() }
      ]
    })
  }

  async handleSave() {
    if (!this.selectedUri) {
      promptAction.showToast({ message: '必须选择一张照片' });
      return;
    }
    let record = new PlantRecord();
    record.groupId = this.groupId;
    record.imageUri = this.selectedUri;
    record.desc = this.inputDesc;

    await DatabaseManager.insertPlantRecord(record);
    this.onSaved();
    this.controller.close();
  }

  build() {
    Column({ space: 15 }) {
      Text('添加新记录').fontSize(18).fontWeight(FontWeight.Bold).margin({top: 10})

      // 图片占位符
      Stack() {
        if (this.selectedUri) {
          Image(this.selectedUri).width('100%').height(160).objectFit(ImageFit.Cover).borderRadius(8)
        } else {
          Column({space: 10}) {
            Image($r('app.media.camera_icon')).width(40).height(40).fillColor('#999')
            Text('点击选择照片 (必填)').fontSize(14).fontColor('#999')
          }.width('100%').height(160).justifyContent(FlexAlign.Center)
          .backgroundColor('#F5F5F5').borderRadius(8)
        }
      }.onClick(() => this.showActionSheet())

      TextArea({ placeholder: '在此输入描述内容(选填)...', text: this.inputDesc })
        .height(80).backgroundColor('#F5F5F5')
        .onChange((val) => this.inputDesc = val)

      Row({ space: 15 }) {
        Button('取消').layoutWeight(1).backgroundColor('#E0E0E0').fontColor('#666')
          .onClick(() => this.controller.close())
        Button('保存').layoutWeight(1).backgroundColor(this.selectedUri ? '#00B96B' : '#CCC')
          .enabled(!!this.selectedUri)
          .onClick(() => this.handleSave())
      }.width('100%')
    }.padding(20).backgroundColor(Color.White).borderRadius(16)
  }
}

@Builder
export function RecordDetailBuilder(name: string, param: Object) { RecordDetail() }

@Component
export struct RecordDetail {
  pathStack: NavPathStack = new NavPathStack();
  @State groupId: number = 0;
  @State groupName: string = '';
  @State records: PlantRecord[] = [];

  // 图片全屏预览状态
  @State previewImage: string = '';

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CreateRecordDialog({
      groupId: this.groupId,
      onSaved: () => { this.loadRecords(); }
    }),
    alignment: DialogAlignment.Center
  })

  async loadRecords() {
    this.records = await DatabaseManager.getRecordsByGroupId(this.groupId);
  }

  // 长按删除菜单
  @Builder DeleteMenu(recordId: string) {
    Menu() {
      MenuItem({ content: '删除此记录' })
        .onClick(async () => {
          await DatabaseManager.deletePlantRecord(recordId);
          this.loadRecords();
        })
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.records.length === 0) {
          Column() { Text('此分组暂无记录，点击右下角添加').fontColor('#999').margin({top: 100}) }.width('100%').height('100%')
        } else {
          Grid() {
            ForEach(this.records, (item: PlantRecord) => {
              GridItem() {
                Column() {
                  Image(item.imageUri)
                    .width('100%').height(140).objectFit(ImageFit.Cover)
                    .borderRadius({topLeft: 12, topRight: 12})
                    .onClick(() => { this.previewImage = item.imageUri; }) // 点击放大

                  Column() {
                    if (item.desc) {
                      Text(item.desc).fontSize(14).fontColor('#333').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis})
                    }
                    Text(item.getFormattedTime()).fontSize(10).fontColor('#999').margin({top: 5})
                  }.padding(10).width('100%').alignItems(HorizontalAlign.Start)
                }
                .backgroundColor(Color.White).borderRadius(12)
                .shadow({ radius: 6, color: '#0A000000', offsetY: 2 })
              }
              .bindContextMenu(this.DeleteMenu(item.id), ResponseType.LongPress) // 长按弹出删除
            })
          }
          .columnsTemplate('1fr 1fr').columnsGap(10).rowsGap(10)
          .padding(15).width('100%').height('100%')
        }

        // 悬浮添加按钮
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Text('+').fontSize(30).fontColor(Color.White).margin({bottom: 4})
        }
        .width(60).height(60).backgroundColor('#00B96B')
        .shadow({ radius: 8, color: '#4000B96B', offsetY: 4 })
        .margin({ right: 20, bottom: 30 })
        .onClick(() => {
          // 打开弹窗前，确保groupId传进去了
          this.dialogController = new CustomDialogController({
            // 🌟 修复报错：加上大括号 {}，并明确声明返回类型为 void
            builder: CreateRecordDialog({
              groupId: this.groupId,
              onSaved: (): void => { this.loadRecords(); }
            }),
            alignment: DialogAlignment.Center
          });
          this.dialogController.open();
        })

        // 图片全屏预览蒙层
        if (this.previewImage) {
          Stack() {
            Image(this.previewImage).width('100%').objectFit(ImageFit.Contain)
          }
          .width('100%').height('100%').backgroundColor('rgba(0,0,0,0.9)')
          .onClick(() => { this.previewImage = ''; }) // 点击任意位置关闭
          .zIndex(99)
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F7FA')
    }
    .title(this.groupName) // 标题栏显示组名
    .onReady((context) => {
      this.pathStack = context.pathStack;
      let params = context.pathInfo.param as Record<string, Object>;
      if (params) {
        this.groupId = params.id as number;
        this.groupName = params.name as string;
        this.loadRecords();
      }
    })
  }
}