import { PromptAction, promptAction } from '@kit.ArkUI';
import { AuthViewModel } from '../viewmodel/AuthViewModel';

PersistentStorage.persistProp('local_username', '');
PersistentStorage.persistProp('isLoggedIn', false);

@Builder
export function LoginBuilder(name: string, param: Object) {
  Login()
}

@Component
export struct Login {
  @State username: string = '';
  @State verifyCode: string = '';

  @State countdown: number = 30;
  @State isCountingDown: boolean = false;
  private timerId: number = -1;

  private pathStack: NavPathStack = new NavPathStack();
  promptAction: PromptAction = this.getUIContext().getPromptAction();

  @StorageProp('local_username') savedUsername: string = '';

  aboutToAppear() {
    if (this.savedUsername) {
      this.username = this.savedUsername;
    }
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  // 获取登录验证码
  async handleGetVerifyCode() {
    let errorMsg = await AuthViewModel.getLoginVerifyCode(this.username);

    if (errorMsg) {
      this.promptAction.showToast({ message: errorMsg });
      return;
    }

    this.isCountingDown = true;
    this.countdown = 30;
    this.promptAction.showToast({ message: '验证码已发送，请查收邮件' });

    this.timerId = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(this.timerId);
        this.isCountingDown = false;
      }
    }, 1000);
  }

  // 登录点击处理
  async handleLogin() {
    let result = await AuthViewModel.login(this.username, this.verifyCode);

    this.promptAction.showToast({ message: result.message });

    if (result.success) {
      // 登录成功，处理状态缓存并跳转
      AppStorage.setOrCreate('isLoggedIn', true);
      AppStorage.setOrCreate('local_username', this.username);

      if (result.token) {
        AppStorage.setOrCreate('user_access_token', result.token);
      }

      this.pathStack.clear();
      this.pathStack.pushPathByName('Layout', null);
    }
  }

  build() {
    NavDestination() {
      Column() {
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

          TextInput({ placeholder: '请输入邮箱子账号', text: this.username })
            .height(50)
            .type(InputType.Email)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => this.username = value)

          Row({ space: 10 }) {
            TextInput({ placeholder: '请输入验证码', text: this.verifyCode })
              .height(50)
              .layoutWeight(1)
              .backgroundColor('#F5F5F5')
              .onChange((value: string) => this.verifyCode = value)

            Button(this.isCountingDown ? `${this.countdown}s后重试` : '获取验证码')
              .height(50)
              .width(120)
              .backgroundColor(this.isCountingDown ? '#CCCCCC' : '#63AAAA')
              .enabled(!this.isCountingDown)
              .onClick(() => this.handleGetVerifyCode())
          }
          .width('100%')

          Button('验证码登录')
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
                this.pathStack.pushPathByName('Register', null);
              })
          }
          .margin({ top: 20 })
        }
        .width('100%')
        .padding({ left: 30, right: 30 })
        .layoutWeight(1)
        Image($r('app.media.farm'))
          .width('100%')
          .objectFit(ImageFit.Cover)
          .align(Alignment.Bottom)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])

      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.White)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}