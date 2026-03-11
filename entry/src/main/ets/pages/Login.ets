import { PromptAction, promptAction } from '@kit.ArkUI';


PersistentStorage.persistProp('local_username', '');
PersistentStorage.persistProp('local_password', '');
PersistentStorage.persistProp('isLoggedIn', false);

@Builder
export function LoginBuilder(name: string, param: Object) {
  Login()
}

@Component
export struct Login {
  @State username: string = '';
  @State password: string = '';

  private pathStack: NavPathStack = new NavPathStack();
  promptAction: PromptAction = this.getUIContext().getPromptAction();

  @StorageProp('local_username') savedUsername: string = '';
  @StorageProp('local_password') savedPassword: string = '';

  handleLogin() {
    if (!this.username || !this.password) {
      this.promptAction.showToast({ message: '账号或密码不能为空' });
      return;
    }

    //校验账号密码是否和本地存储的一致
    if (this.username === this.savedUsername && this.password === this.savedPassword) {
      this.promptAction.showToast({ message: '登录成功' });
      AppStorage.setOrCreate('isLoggedIn', true);
      this.pathStack.clear();
      this.pathStack.pushPathByName('Layout', null);
    } else {
      this.promptAction.showToast({ message: '账号或密码错误，请先注册' });
    }
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Image($r('app.media.app_icon'))
          .width(80)
          .height(80)
          .margin({ top: 80, bottom: 30 })
          .borderRadius(16)

        Text('智慧农业控制系统')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 40 })

        //输入框
        TextInput({ placeholder: '请输入账号', text: this.username })
          .height(50)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => this.username = value)

        TextInput({ placeholder: '请输入密码', text: this.password })
          .height(50)
          .type(InputType.Password)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => this.password = value)

        //按钮
        Button('登录')
          .width('100%')
          .height(45)
          .backgroundColor('#63AAAA')
          .margin({ top: 20 })
          .onClick(() => this.handleLogin())

        Row() {
          Text('还没有账号？').fontColor('#999').fontSize(14)
          Text('立即注册')
            .fontColor('#63AAAA')
            .fontSize(14)
            .onClick(() => {
              //跳转到注册页
              this.pathStack.pushPathByName('Register', null);
            })
        }
        .margin({ top: 20 })
      }
      .width('100%')
      .height('100%')
      .padding(30)
      .backgroundColor(Color.White)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}