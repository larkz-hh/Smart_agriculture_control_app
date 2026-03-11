import { promptAction } from '@kit.ArkUI';

@Builder
export function RegisterBuilder(name: string, param: Object) {
  Register()
}

@Component
struct Register {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';

  private pathStack: NavPathStack = new NavPathStack();

  handleRegister() {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '请完整填写账号和密码' });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次密码输入不一致' });
      return;
    }

    AppStorage.setOrCreate('local_username', this.username);
    AppStorage.setOrCreate('local_password', this.password);

    promptAction.showToast({ message: '注册成功，请登录' });

    this.pathStack.pop();
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Text('注册新账号')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Start)
          .margin({ top: 40, bottom: 20 })

        TextInput({ placeholder: '请输入新账号', text: this.username })
          .height(50)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => this.username = value)

        TextInput({ placeholder: '请输入密码', text: this.password })
          .height(50)
          .type(InputType.Password)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => this.password = value)

        TextInput({ placeholder: '请确认密码', text: this.confirmPassword })
          .height(50)
          .type(InputType.Password)
          .backgroundColor('#F5F5F5')
          .onChange((value: string) => this.confirmPassword = value)

        Button('注 册')
          .width('100%')
          .height(45)
          .backgroundColor('#63AAAA')
          .margin({ top: 30 })
          .onClick(() => this.handleRegister())

        Button('返回登录')
          .width('100%')
          .height(45)
          .backgroundColor(Color.Transparent)
          .fontColor('#999')
          .onClick(() => {
            this.pathStack.pop();
          })
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