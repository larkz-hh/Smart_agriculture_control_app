import util from "@ohos.util";

@ObservedV2
export class MessageModel {
  role: 'user' | 'assistant' | 'system';
  @Trace content: string;
  timestamp: number;
  id: string;

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