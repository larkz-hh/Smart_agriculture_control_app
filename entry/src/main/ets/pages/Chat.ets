import { MessageModel } from '../model/MessageModel';
import { Markdown, MarkdownController } from '@luvi/lv-markdown-in';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { fileIo } from '@kit.CoreFileKit';
import util from '@ohos.util';
import { common } from '@kit.AbilityKit';
import { AiService } from '../services/AIService';
import { DatabaseManager } from '../data/DatabaseManager';

@ComponentV2
export struct Chat {
  @Local messageList: MessageModel[] = [
    new MessageModel('assistant', '你好！我是智慧农业AI助手，可以问我有关农业方面的知识，或者拍植物照片发给我分析哦。')
  ];
  @Local inputValue: string = '';
  @Local isLoading: boolean = false;
  @Local isDeepThinking: boolean = false;
  //图片相关状态和弹窗控制
  @Local selectedImageUri: string = '';
  @Local selectedImageBase64: string = '';
  @Local isSheetShow: boolean = false;

  private scroller: Scroller = new Scroller();
  private mdController: MarkdownController = new MarkdownController();
  @Param @Require pathStack: NavPathStack;
  @Local currentSessionId: number = -1;

  aboutToAppear() {
    this.mdController.setThreadRenderEnable(true).setTextColor('#333333').setTextSize(16);
  }

  //调用系统相册选择
  async pickPhoto() {
    try {
      let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      PhotoSelectOptions.maxSelectNumber = 1;
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let photoSelectResult = await photoPicker.select(PhotoSelectOptions);
      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        this.processImageUri(photoSelectResult.photoUris[0]);
      }
    } catch (err) {
      console.error('选择图片失败:', err);
    }
  }

  //调用系统相机拍照
  async takePhoto() {
    try {
      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      let context = getContext(this) as common.UIAbilityContext;
      let result = await cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], pickerProfile);
      if (result && result.resultUri) {
        this.processImageUri(result.resultUri);
      }
    } catch (err) {
      console.error('拍照失败:', err);
    }
  }

  // 图片转为Base64
  async processImageUri(uri: string) {
    this.selectedImageUri = uri;
    try {
      let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      let stat = fileIo.statSync(file.fd);
      let buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file.fd);

      let base64Helper = new util.Base64Helper();
      let base64Str = base64Helper.encodeToStringSync(new Uint8Array(buffer));
      this.selectedImageBase64 = 'data:image/jpeg;base64,' + base64Str;
    } catch (e) {
      console.error('图片转换Base64失败:', e);
    }
  }

  async sendMessage() {
    if ((!this.inputValue.trim() && !this.selectedImageUri) || this.isLoading) return;
    this.isLoading = true;
    // 构造用户消息
    let userText = this.inputValue.trim();
    let userMsg = new MessageModel('user', userText);
    if (this.selectedImageBase64) {
      userMsg.imageUri = this.selectedImageUri;
      userMsg.imageBase64 = this.selectedImageBase64;
    }
    this.messageList.push(userMsg);
    if (this.currentSessionId === -1) {
      this.currentSessionId = await DatabaseManager.insertSession('新对话...', Date.now());

      //后台异步让AI生成标题并更新数据库
      AiService.generateChatTitle(userText).then((title) => {
        DatabaseManager.updateSessionTitle(this.currentSessionId, title);
      });
    }
    //将用户发的消息存入数据库
    await DatabaseManager.insertMessage(userMsg, this.currentSessionId);
    //清空输入框和图片
    this.inputValue = '';
    this.selectedImageUri = '';
    this.selectedImageBase64 = '';
    this.scrollToBottom();

    //构建并存入 AI 的空消息容器
    let aiMessage = new MessageModel('assistant', '');
    aiMessage.timestamp = Date.now() + 10;
    this.messageList.push(aiMessage);


    AiService.sendStreamChat(
      this.messageList.slice(0, this.messageList.length - 1),
      this.isDeepThinking,
      (chunk: string) => {
        aiMessage.content += chunk;
        this.scrollToBottom();
      },
      () => {
        this.isLoading = false;
        //流式接收完毕后，将完整的 AI 回复存入数据库
        DatabaseManager.insertMessage(aiMessage, this.currentSessionId);
      },
      (errMsg: string) => {
        aiMessage.content += errMsg;
        this.isLoading = false;
        DatabaseManager.insertMessage(aiMessage, this.currentSessionId);
      }
    );
  }
  //加载历史记录
  async loadHistorySession(sessionId: number) {
    this.currentSessionId = sessionId;
    let historyMsgs = await DatabaseManager.getMessagesBySession(sessionId);

    if (historyMsgs && historyMsgs.length > 0) {
      //使用解构语法 [...数组] 强制赋予新内存地址。
      // 在 ArkUI V2 中，如果直接等号赋值旧数组，有时框架会察觉不到变化，导致页面假死不跳转！
      this.messageList = [...historyMsgs];
    } else {
      this.messageList = [new MessageModel('assistant', '（此会话暂无记录）')];
    }
    this.scrollToBottom();
  }
  scrollToBottom() {
    setTimeout(() => { this.scroller.scrollEdge(Edge.Bottom); }, 100);
  }

  //底部操作弹窗
  @Builder AttachmentSheet() {
    Column() {
      Row() {
        Text('选择操作').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333')
      }
      .width('100%').padding(15).justifyContent(FlexAlign.Center)

      Row() {

        Column({space: 8}) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Image($r('app.media.camera_icon'))
              .width(28).height(28)
          }
          .width(60).height(60).backgroundColor('#F5F5F5')
          .onClick(() => {
            this.isSheetShow = false;
            this.takePhoto();
          })

          Text('拍照').fontSize(13).fontColor('#666')
        }

        Column({space: 8}) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            Image($r('app.media.album_icon'))
              .width(28).height(28)
          }
          .width(60).height(60).backgroundColor('#F5F5F5')
          .onClick(() => {
            this.isSheetShow = false;
            this.pickPhoto();
          })

          Text('相册').fontSize(13).fontColor('#666')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({top: 10, bottom: 40})
    }
    .backgroundColor(Color.White)
    .borderRadius({topLeft: 20, topRight: 20})
  }

  @Builder chatBubble(item: MessageModel) {
    Column() {
      Text(item.getFormattedTime ? item.getFormattedTime() : '')
        .fontSize(10).fontColor('#999').margin({ top: 10, bottom: 4 })
        .width('100%').textAlign(item.role === 'user' ? TextAlign.End : TextAlign.Start)

      Row() {
        if (item.role === 'user') {
          Blank()
          Column({space: 5}) {
            if (item.imageUri) {
              Image(item.imageUri).width(120).borderRadius(8).objectFit(ImageFit.Cover)
            }
            if (item.content) {
              Text(item.content).fontSize(16).fontColor(Color.White)
            }
          }
          .padding(12).backgroundColor('#00B96B')
          .borderRadius({ topLeft: 15, bottomLeft: 15, bottomRight: 4 })
          .constraintSize({ maxWidth: '70%' }).alignItems(HorizontalAlign.End)

        } else {
          Image($r('app.media.ai_chat_icon')).width(30).height(30).margin({ right: 8 }).flexShrink(0)

          Column() {
            Markdown({ text: item.content, controller: this.mdController })
          }
          .alignItems(HorizontalAlign.Start)
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius({ topRight: 15, bottomRight: 15, bottomLeft: 4 })
          // 直接用 layoutWeight(1)
          // 强制系统先算好剩余的所有宽度，框住Markdown组件
          .layoutWeight(1)
          .shadow({ radius: 4, color: '#10000000' })
          //用一个固定宽度的透明块占位
          //保持气泡右侧始终有留白，实现 maxWidth: 85% 的视觉效果
          Column().width('12%')
        }
      }.width('100%').alignItems(VerticalAlign.Top)
    }.padding({ left: 15, right: 15 })
  }

  build() {
    Column() {
      // 头部
      Row() {
        Text('农业智能专家')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000')
          .layoutWeight(1)
          .padding({ left: 15 })

        //功能图标区
        Row({ space: 20 }) {
          // 历史记录
          Image($r('app.media.history_icon'))
            .width(24)
            .height(24)
            .onClick(() => {
              //跳转到 History，并监听返回结果
              this.pathStack.pushPathByName('History', null, (popInfo: PopInfo) => {
                if (popInfo && popInfo.result) {
                  let selectedSessionId = popInfo.result as number;
                  this.loadHistorySession(selectedSessionId);
                }
              });
            })

          // 新建会话
          Image($r('app.media.add_chat_icon'))
            .width(24)
            .height(24)
            .onClick(() => {
              //清空当前聊天列表，准备新的对话
              this.currentSessionId = -1;
              this.messageList = [new MessageModel('assistant', '你好！我是智慧农业AI助手，可以问我有关农业方面的知识，或者拍植物照片发给我分析哦。')];
            })
        }
        .padding({ right: 15 })
      }
      .width('100%')
      .padding({ top: 15, bottom: 15 })
      .backgroundColor('#F5F5F5')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
      // 聊天列表
      List({ scroller: this.scroller }) {
        ForEach(this.messageList, (item: MessageModel) => {
          ListItem() { this.chatBubble(item) }
        }, (item: MessageModel) => item.id) //使用唯一的 UUID 作为渲染 Key
      }
      .layoutWeight(1).width('100%').backgroundColor('#F0F2F5').edgeEffect(EdgeEffect.Spring)

      // 在输入框上方显示图片预览图
      if (this.selectedImageUri) {
        Row() {
          Stack({alignContent: Alignment.TopEnd}) {
            Image(this.selectedImageUri)
              .width(60)
              .height(60)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
            //删除图片的红叉
            Text('×').fontSize(14).fontColor(Color.White).backgroundColor('#FF4D4F')
              .width(18).height(18).textAlign(TextAlign.Center).borderRadius(9)
              .offset({x: 5, y: -5})
              .onClick(() => {
                this.selectedImageUri = '';
                this.selectedImageBase64 = '';
              })
          }
        }.width('100%').padding({left: 15, bottom: 5, top: 5}).backgroundColor(Color.White)
      }

      //开关和输入区
      Row() {
        Text('深度思考').fontSize(12).fontColor('#666')
        Toggle({ type: ToggleType.Switch, isOn: this.isDeepThinking })
          .selectedColor('#00B96B').width(36).height(20).margin({ left: 8 })
          .onChange((isOn: boolean) => this.isDeepThinking = isOn)
      }.width('100%').padding({ left: 15, right: 15, top: 8, bottom: 2 }).backgroundColor(Color.White)

      Row({ space: 10 }) {
        TextInput({ text: this.inputValue, placeholder: '描述植物的问题...' })
          .layoutWeight(1).height(45).enterKeyType(EnterKeyType.Send)
          .onChange((val: string) => this.inputValue = val)
          .onSubmit(() => this.sendMessage())

        //动态按钮逻辑：有字或有图时显示发送，否则显示 + 号
        if (this.inputValue.trim().length > 0 || this.selectedImageUri.length > 0) {
          Button('发送')
            .height(45).backgroundColor(this.isLoading ? '#CCC' : '#00B96B')
            .enabled(!this.isLoading)
            .onClick(() => this.sendMessage())
        } else {
          Button('+')
            .height(45).width(45).fontSize(24).fontColor('#666')
            .backgroundColor('#F0F0F0')
            .onClick(() => {
              this.isSheetShow = true;
            })
        }
      }.padding(10).backgroundColor(Color.White)
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .width('100%').height('100%')
    .bindSheet($$this.isSheetShow, this.AttachmentSheet(), {
      height: 180,
      dragBar: true,
      backgroundColor: Color.White
    })
  }
}