import { promptAction } from '@kit.ArkUI';
import { AuthService } from '../services/auth/AuthService';

@Builder
export function RegisterBuilder(name: string, param: Object) {
  Register()
}

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

  // 密码格式校验
  validatePassword(pwd: string): string {
    if (pwd.length < 8) return '密码长度至少为8位';
    if (pwd === this.email) return '密码不可与邮箱地址相同';
    let typeCount = 0;
    if (/[A-Z]/.test(pwd)) typeCount++; //大写
    if (/[a-z]/.test(pwd)) typeCount++; //小写
    if (/[0-9]/.test(pwd)) typeCount++; //数字
    if (/[^A-Za-z0-9]/.test(pwd)) typeCount++; // 符号
    if (typeCount < 2) return '密码需至少包含大写、小写、数字、符号中的2种';
    return '';
  }

  //获取验证码点击处理
  async handleGetVerifyCode() {
    //检查邮箱
    if (!this.email || !this.email.includes('@')) {
      promptAction.showToast({ message: '请填写正确的邮箱地址' });
      return;
    }

    //必须先填写密码才能获取验证码
    if (!this.password || !this.confirmPassword) {
      promptAction.showToast({ message: '请先填写并确认密码' });
      return;
    }
    // 两次密码是否一致
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入密码不一致，请修改后再获取验证码' });
      return;
    }
    //密码格式是否合规
    let pwdError = this.validatePassword(this.password);
    if (pwdError) {
      promptAction.showToast({ message: pwdError });
      return;
    }
    //通过前置检查，开始倒计时和发送请求
    this.isCountingDown = true;
    this.countdown = 30;
    try {
      await AuthService.sendVerifyCode(this.email);
      promptAction.showToast({ message: '验证码已发送，请查收邮件' });
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
      promptAction.showToast({ message: msg });
    }
  }

  //注册点击处理
  async handleRegister() {
    if (!this.email || !this.password || !this.confirmPassword || !this.verifyCode) {
      promptAction.showToast({ message: '请完整填写所有信息' });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次密码输入不一致' });
      return;
    }
    let pwdError = this.validatePassword(this.password);
    if (pwdError) {
      promptAction.showToast({ message: pwdError });
      return;
    }

    try {
      let res = await AuthService.registerUser(this.email, this.verifyCode, this.password);

      if (res.ret && res.ret.code === 0) {
        promptAction.showToast({ message: '注册成功，请登录' });
        //保存账号
        AppStorage.setOrCreate('local_username', this.email);
        this.pathStack.pop();
      } else if (res.ret && res.ret.code === 203818130) {
        promptAction.showToast({ message: '该邮箱已被注册，请直接返回登录' });
      } else {
        let errorMsg = res.ret?.msg || '注册失败，请检查验证码是否正确';
        promptAction.showToast({ message: errorMsg });
      }
    } catch (error) {
      let msg = error instanceof Error ? error.message : '网络异常，请重试';
      promptAction.showToast({ message: msg });
    }
  }

  build() {
    NavDestination() {
      Column({ space: 15 }) {
        Text('注册新账号')
          .fontSize(24).fontWeight(FontWeight.Bold).width('100%')
          .textAlign(TextAlign.Start).margin({ top: 40, bottom: 20 })

        TextInput({ placeholder: '请输入邮箱地址', text: this.email })
          .height(50).type(InputType.Email).backgroundColor('#F5F5F5')
          .onChange((value: string) => this.email = value)

        TextInput({ placeholder: '请输入密码 (至少8位，含2种字符)', text: this.password })
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
            .backgroundColor(this.isCountingDown ? '#CCCCCC' : '#63AAAA')
            .enabled(!this.isCountingDown)
            .onClick(() => this.handleGetVerifyCode())
        }.width('100%')

        Button('注 册')
          .width('100%').height(45).backgroundColor('#63AAAA')
          .margin({ top: 30 })
          .onClick(() => this.handleRegister())

        Button('返回登录')
          .width('100%').height(45).backgroundColor(Color.Transparent).fontColor('#999')
          .onClick(() => { this.pathStack.pop(); })
      }
      .width('100%').height('100%').padding(30).backgroundColor(Color.White)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}