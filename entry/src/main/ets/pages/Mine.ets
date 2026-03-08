import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

interface MineItem {
  icon: ResourceStr;
  text: string;
  tag?: string;
}

@Component
export struct Mine {
  @State userAvatar: string | Resource = $r('app.media.app_icon'); // 默认头像
  @State userName: string = "默认名字";

  // 列表数据
  private mineList: MineItem[] = [
    { icon: $r('app.media.app_icon'), text: '设置' },
    { icon: $r('app.media.app_icon'), text: '关于智慧农业' },
    { icon: $r('app.media.app_icon'), text: '退出登录' },
  ];

  // 选择图片
  async selectImage() {
    try {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      PhotoSelectOptions.maxSelectNumber = 1;
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let photoSelectResult = await photoPicker.select(PhotoSelectOptions);
      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        this.userAvatar = photoSelectResult.photoUris[0];
      }
    } catch (err) {
      console.error('PhotoViewPicker.select failed: ' + err);
    }
  }

  @Builder
  itemBuilder(item: MineItem) {
    Row() {
      // 左侧图标
      Stack() {
        Circle({ width: 36, height: 36 }).fill('#F2F2F2')
        Image(item.icon)
          .width(20)
          .height(20)
      }
      .margin({ right: 15 })

      // 中间文字
      Text(item.text)
        .fontSize(16)
        .fontColor('#333')
        .layoutWeight(1)

      // 右侧箭头
      Image($r('app.media.arrow_right_ic'))
        .width(16)
        .height(16)
        .opacity(0.3)
    }
    .width('100%')
    .height(60)
    .padding({ left: 15, right: 15 })
    .onClick(() => {
      // 后期跳转逻辑
      console.info(`点击了: ${item.text}`)
    })
  }

  build() {
    Scroll() {
      Column() {
        // 顶部用户信息区
        Row() {
          Column({ space: 8 }) {
            Row() {
              Text(this.userName)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
              Image($r('app.media.arrow_right_ic'))
                .width(18)
                .margin({ left: 10 })
            }
            Text('下午好, 欢迎回来')
              .fontSize(14)
              .fontColor('#999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 圆形头像
          Image(this.userAvatar)
            .width(80)
            .height(80)
            .borderRadius(40)
            .clip(true)
            .onClick(() => this.selectImage()) // 点击换头像
            .border({ width: 2, color: Color.White })
            .shadow({ radius: 10, color: '#10000000' })
        }
        .width('100%')
        .padding({ left: 25, right: 25, top: 10, bottom: 70 })




        //  功能列表卡片
        Column() {
          ForEach(this.mineList, (item: MineItem, index: number) => {
            this.itemBuilder(item)
            // 如果不是最后一项，添加分割线
            if (index !== this.mineList.length - 1) {
              Divider()
                .strokeWidth(0.5)
                .color('#F0F0F0')
                .margin({ left: 65, right: 15 })
            }
          })
        }
        .width('92%')
        .backgroundColor(Color.White)
        .borderRadius(20)
        .shadow({ radius: 20, color: '#08000000' })
        .padding({ top: 10, bottom: 10 })
        .margin({ bottom: 50 })

      }
      .width('100%')
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .height('100%')
    .backgroundColor('#F4F6FB')
  }

  @Builder
  statItem(count: string, label: string) {
    Row() {
      Text(count)
        .fontSize(14)
        .fontColor('#63AAAA')
        .fontWeight(FontWeight.Medium)
      Text(label)
        .fontSize(12)
        .fontColor('#999')
        .margin({ left: 4 })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}