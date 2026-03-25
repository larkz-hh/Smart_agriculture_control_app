import { PromptAction, promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/auth/AuthService';

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

  async handleGetVerifyCode() {
    if (!this.username || !this.username.includes('@')) {
      this.promptAction.showToast({ message: '请填写正确的邮箱地址' });
      return;
    }

    this.isCountingDown = true;
    this.countdown = 30;
    try {
      await AuthService.sendVerifyCode(this.username);
      this.promptAction.showToast({ message: '验证码已发送，请查收邮件' });
      this.timerId = setInterval(() => {
        this.countdown -= 1;
        if (this.countdown <= 0) {
          clearInterval(this.timerId);
          this.isCountingDown = false;
        }
      }, 1000);
    } catch (error) {
      this.isCountingDown = false;
      let msg = error instanceof Error ? error.message : '发送失败';
      this.promptAction.showToast({ message: msg });
    }
  }

  async handleLogin() {
    if (!this.username || !this.verifyCode) {
      this.promptAction.showToast({ message: '请完整填写邮箱和验证码' });
      return;
    }

    try {
      let res = await AuthService.signInByVerifyCode(this.username, this.verifyCode);

      if (res.ret && res.ret.code === 0) {
        this.promptAction.showToast({ message: '登录成功' });

        AppStorage.setOrCreate('isLoggedIn', true);
        AppStorage.setOrCreate('local_username', this.username);
        if (res.accessToken?.token) {
          AppStorage.setOrCreate('user_access_token', res.accessToken.token);
        }

        this.pathStack.clear();
        this.pathStack.pushPathByName('Layout', null);

      } else if (res.ret && res.ret.code === 203818032) {
        this.promptAction.showToast({ message: '该账号尚未注册，请先注册' });
      } else {
        let errorMsg = res.ret?.msg || '登录失败，请检查验证码';
        this.promptAction.showToast({ message: errorMsg });
      }

    } catch (error) {
      this.promptAction.showToast({ message: '网络异常，请重试' });
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

        TextInput({ placeholder: '请输入邮箱账号', text: this.username })
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