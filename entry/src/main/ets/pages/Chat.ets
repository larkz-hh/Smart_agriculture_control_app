import { MessageModel } from '../model/MessageModel';
import { AiService } from '../services/AIService';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';

@ComponentV2
export struct Chat {
  @Local messageList: MessageModel[] = [
    new MessageModel('assistant', '你好！我是智慧农业AI助手，有什么可以帮您的？')
  ];
  @Local inputValue: string = '';
  @Local isLoading: boolean = false;
  private scroller: Scroller = new Scroller();
  private mdController: MarkdownController = new MarkdownController();
  aboutToAppear() {
    this.mdController
      .setThreadRenderEnable(true)
      .setTextColor('#333333')
      .setTextSize(16)
  }

  async sendMessage() {
    if (!this.inputValue.trim() || this.isLoading) return;

    const userText = this.inputValue.trim();
    this.inputValue = '';
    this.isLoading = true;
    this.messageList.push(new MessageModel('user', userText));
    this.scrollToBottom();

    let aiMessage = new MessageModel('assistant', '');
    this.messageList.push(aiMessage);

    AiService.sendStreamChat(
      this.messageList.slice(0, this.messageList.length - 1),
      //将每次吐出的字追加到 UI上
      (chunk: string) => {
        aiMessage.content += chunk;
        this.scrollToBottom();
      },
      //结束时取消 loading 状态
      () => {
        this.isLoading = false;
      },
      //报错时的处理
      (errMsg: string) => {
        aiMessage.content += errMsg;
        this.isLoading = false;
      }
    );
  }

  //滚动到底部
  scrollToBottom() {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);
  }

  //气泡构建
  @Builder chatBubble(item: MessageModel) {
    Column() {
      Text(item.getFormattedTime ? item.getFormattedTime() : '')
        .fontSize(10)
        .fontColor('#999')
        .margin({ top: 10, bottom: 4 })
        .width('100%')
        .textAlign(item.role === 'user' ? TextAlign.End : TextAlign.Start)

      Row() {
        if (item.role === 'user') {
          Blank() // 用户气泡靠右
          Text(item.content)
            .fontSize(16)
            .fontColor(Color.White)
            .padding(12)
            .backgroundColor('#63AAAA')
            .borderRadius({ topLeft: 15, bottomLeft: 15, bottomRight: 4 })
            .constraintSize({ maxWidth: '70%' })
        } else {
          Image($r('app.media.ai_chat_icon'))
            .width(30)
            .height(30)
            .margin({ right: 8 })
            .flexShrink(0)

          // Text(item.content)
          //   .fontSize(16)
          //   .fontColor('#333')
          //   .padding(12)
          //   .backgroundColor(Color.White)
          //   .borderRadius({ topRight: 15, bottomRight: 15, bottomLeft: 4 })
          //   .constraintSize({ maxWidth: '70%' })
          //   .shadow({ radius: 4, color: '#10000000' })
          // Blank()
          Row() {
            Markdown({
              text: item.content,
              controller: this.mdController
            }).flexShrink(1)
          }
          .alignItems(VerticalAlign.Top)
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius({ topRight: 15, bottomRight: 15, bottomLeft: 4 })
          .constraintSize({ maxWidth: '85%' })
          .shadow({ radius: 4, color: '#10000000' })
          .flexShrink(1)
          .clip(true)
          Blank()

        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .padding({ left: 15, right: 15 })
  }

  build() {
    Column() {
      Row() {
        Blank().layoutWeight(1)
        Text('智能助手')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(2)
          .textAlign(TextAlign.Center)
        Text('清空记录')
          .fontSize(14)
          .fontColor('#999')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .padding({ right: 15 })
          .onClick(() => {
            this.messageList = [
              new MessageModel('assistant', '对话已清空。您可以开始新的提问了。')
            ];
          })
      }
      .width('100%')
      .padding({ top: 15, bottom: 15 })
      .backgroundColor('#F5F5F5')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])

      List({ scroller: this.scroller }) {
        ForEach(this.messageList, (item: MessageModel) => {
          ListItem() {
            this.chatBubble(item)
          }
        }, (item: MessageModel, index: number) => index.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .backgroundColor('#F0F2F5')
      .edgeEffect(EdgeEffect.Spring)

      Row({ space: 10 }) {
        TextInput({ text: this.inputValue, placeholder: '输入您的问题...' })
          .layoutWeight(1)
          .height(45)
          .enterKeyType(EnterKeyType.Send)
          .onChange((val: string) => this.inputValue = val)
          .onSubmit(() => this.sendMessage())

        Button('发送')
          .height(45)
          .backgroundColor(this.inputValue.trim() ? '#63AAAA' : '#CCC')
          .enabled(this.inputValue.trim().length > 0 && !this.isLoading)
          .onClick(() => this.sendMessage())
      }
      .padding(10)
      .backgroundColor(Color.White)
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }
}