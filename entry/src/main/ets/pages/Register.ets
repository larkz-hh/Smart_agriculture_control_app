import { promptAction } from '@kit.ArkUI';
import { AuthViewModel } from '../viewmodel/AuthViewModel';

@Builder
export function RegisterBuilder(name: string, param: Object) {
  Register()
}

@Preview
@Component
export struct Register {
  @State email: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State verifyCode: string = '';

  // 验证码倒计时相关
  @State countdown: number = 30;
  @State isCountingDown: boolean = false;
  private timerId: number = -1;

  private pathStack: NavPathStack = new NavPathStack();

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  // 判断“获取验证码”按钮是否可以点击
  isGetCodeEnabled(): boolean {
    // 只有当账号、密码、确认密码都填写了，且不在倒计时中，才能点击
    return this.email.trim().length > 0 &&
      this.password.length > 0 &&
      this.confirmPassword.length > 0 &&
      !this.isCountingDown;
  }

  // “注册”按钮是否可以点击
  isRegisterEnabled(): boolean {
    return this.email.trim().length > 0 &&
      this.password.length > 0 &&
      this.confirmPassword.length > 0 &&
      this.verifyCode.trim().length > 0;
  }
  // 获取验证码点击处理
  async handleGetVerifyCode() {
    let errorMsg = await AuthViewModel.getVerifyCode(this.email, this.password, this.confirmPassword);

    if (errorMsg) {
      promptAction.showToast({ message: errorMsg });
      return;
    }

    // 校验全部通过并发送成功，开启计时器，倒计时30s
    promptAction.showToast({ message: '验证码已发送，请查收邮件' });
    this.isCountingDown = true;
    this.countdown = 30;
    this.timerId = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(this.timerId);
        this.isCountingDown = false;
      }
    }, 1000);
  }

  // 注册点击处理
  async handleRegister() {
    let result = await AuthViewModel.register(this.email, this.password, this.confirmPassword, this.verifyCode);

    promptAction.showToast({ message: result.message });

    if (result.success) {
      // 保存账号
      AppStorage.setOrCreate('local_username', this.email);
      this.pathStack.pop();
    }
  }

  build() {
    NavDestination() {
      Column() {
        Column({ space: 15 }) {
          Text('注册新账号')
            .fontSize(24).fontWeight(FontWeight.Bold).width('100%')
            .textAlign(TextAlign.Start).margin({ top: 40, bottom: 20 })

          TextInput({ placeholder: '请输入邮箱地址', text: this.email })
            .height(50).type(InputType.Email).backgroundColor('#F5F5F5')
            .onChange((value: string) => this.email = value)

          TextInput({ placeholder: '请输入密码', text: this.password })
            .height(50).type(InputType.Password).backgroundColor('#F5F5F5')
            .onChange((value: string) => this.password = value)

          TextInput({ placeholder: '请确认密码', text: this.confirmPassword })
            .height(50).type(InputType.Password).backgroundColor('#F5F5F5')
            .onChange((value: string) => this.confirmPassword = value)

          Row({ space: 10 }) {
            TextInput({ placeholder: '请输入验证码', text: this.verifyCode })
              .height(50).layoutWeight(1).backgroundColor('#F5F5F5')
              .onChange((value: string) => this.verifyCode = value)

            Button(this.isCountingDown ? `${this.countdown}s后重试` : '获取验证码')
              .height(50).width(120)
              .backgroundColor(this.isGetCodeEnabled() ? '#63AAAA' : '#CCCCCC')
              .enabled(this.isGetCodeEnabled()) // 控制是否可点击
              .onClick(() => this.handleGetVerifyCode())
          }.width('100%')

          Button('注 册')
            .width('100%').height(45)
            .backgroundColor(this.isRegisterEnabled() ? '#63AAAA' : '#CCCCCC')
            .enabled(this.isRegisterEnabled())
            .margin({ top: 30 })
            .onClick(() => this.handleRegister())

          Button('返回登录')
            .width('100%').height(45).backgroundColor(Color.Transparent).fontColor('#999')
            .onClick(() => { this.pathStack.pop(); })
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