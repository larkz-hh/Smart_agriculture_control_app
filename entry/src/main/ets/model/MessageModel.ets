import util from "@ohos.util";


@ObservedV2
export class MessageModel {
  role: 'user' | 'assistant' | 'system';
  @Trace content: string;
  @Trace imageBase64?: string; //传给大模型的Base64数据
  @Trace imageUri?: string; //本地UI渲染用的文件路径

  timestamp: number;
  id: string;
  sessionId: number = -1;

  constructor(role: 'user' | 'assistant' | 'system', content: string) {
    this.role = role;
    this.content = content;
    this.timestamp = Date.now();
    this.id = util.generateRandomUUID(true);
  }

  getFormattedTime(): string {
    const date = new Date(this.timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
}
export interface SessionItem {
  id: number;
  title: string;
  timestamp: number;
}