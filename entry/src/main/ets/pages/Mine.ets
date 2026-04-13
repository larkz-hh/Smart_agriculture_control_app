import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

interface MineItem {
  icon: ResourceStr;
  text: string;
  tag?: string;
}
@Preview
@Component
export struct Mine {
  pathStack?: NavPathStack;

  @StorageLink('isLoggedIn') isLoggedIn: boolean = false;
  @StorageProp('local_username') savedUsername: string = '';

  @State userAvatar: string | Resource = $r('app.media.app_icon');
  @State greeting: string = '';
  aboutToAppear() {
    this.updateGreeting();
  }
  //判断时间
  updateGreeting() {
    const now = new Date();
    const hour = now.getHours();
    if (hour >= 0 && hour < 12) {
      this.greeting = '上午好';
    } else if (hour >= 12 && hour < 18) {
      this.greeting = '下午好';
    } else {
      this.greeting = '晚上好';
    }
  }

  private mineList: MineItem[] = [
    { icon: $r('app.media.setting'), text: '设置' },
    { icon: $r('app.media.service'), text: '客服' },
    { icon: $r('app.media.about'), text: '关于' },
    { icon: $r('app.media.logout'), text: '退出登录' },
  ];

  // 选择图片
  async selectImage() {
    if (this.isLoggedIn) {
      try {
        //创建配置对象
        let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
        //过滤条件
        PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
        //限制最大选择数量
        PhotoSelectOptions.maxSelectNumber = 1;
        //实例化相册选择器组件
        let photoPicker = new photoAccessHelper.PhotoViewPicker();
        //拉起系统相册界面
        let photoSelectResult = await photoPicker.select(PhotoSelectOptions);
        if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
          this.userAvatar = photoSelectResult.photoUris[0];
        }
      } catch (err) {
        console.error('PhotoViewPicker.select failed: ' + err);
      }
    } else {
      if (!this.isLoggedIn && this.pathStack) {
        this.pathStack.pushPathByName('Login', null);
      }
    }
  }

  @Builder
  itemBuilder(item: MineItem) {
    Row() {
      // 左侧图标
      Stack() {
        Circle({ width: 36, height: 36 }).fill('#FFFFFF')
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
      if (item.text === '退出登录') {
        if (!this.isLoggedIn) {
          promptAction.showToast({ message: '您还没有登录哦' });
          return;
        }
        AppStorage.setOrCreate('isLoggedIn', false);
        promptAction.showToast({ message: '已退出登录' });
      } else if (item.text === '关于') {
        // 跳转到关于页面
        if (this.pathStack) {
          this.pathStack.pushPathByName('About', null);
        }
      } else if (item.text === '客服') {
        // 跳转到客服页面
        if (this.pathStack) {
          this.pathStack.pushPathByName('CustomerService', null);
        }
      } else {
        promptAction.showToast({ message: '功能开发中...' });
      }
    })
  }

  build() {
    Scroll() {
      Column() {
        // 顶部用户信息区
        Row() {
          Column({ space: 8 }) {
            if (this.isLoggedIn) {
              Row() {
                Text(this.savedUsername)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
              }
              Text(this.greeting + ', 欢迎回来').fontSize(14).fontColor('#999')
            } else {
              //未登录
              Row() {
                Text('您还未登录')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .onClick(() => {
                    if (!this.isLoggedIn && this.pathStack) {
                      this.pathStack.pushPathByName('Login', null);
                    }
                  })
                Image($r('app.media.arrow_right_ic')).width(18).margin({ left: 10 })
              }
              Text('点击此处登录 / 注册账号').fontSize(14).fontColor('#63AAAA')
                .onClick(() => {
                  if (!this.isLoggedIn && this.pathStack) {
                    this.pathStack.pushPathByName('Login', null);
                  }
                })
            }
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



        //功能列表
        Column() {
          ForEach(this.mineList, (item: MineItem, index: number) => {
            this.itemBuilder(item)
            //如果不是最后一项，添加分割线
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