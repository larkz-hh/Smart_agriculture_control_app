// 发送给接口的消息体
export class ApiMessage {
  role: string;
  content: string | VisionContentItem[];

  constructor(role: string, content: string | VisionContentItem[]) {
    this.role = role;
    this.content = content;
  }
}

//接收流式返回的 JSON 结构模型
export class DeltaModel {
  content?: string;
}

export class ChoiceModel {
  delta?: DeltaModel;
}

export class StreamResponseModel {
  choices?: ChoiceModel[];
}

class NonStreamMessage {
  content?: string;
}
class NonStreamChoice {
  message?: NonStreamMessage;
}
export class NonStreamResponseModel {
  choices?: NonStreamChoice[];
}

export class VisionImageUrl {
  url: string;
  constructor(url: string) {
    this.url = url;
  }
}

export class VisionContentItem {
  type: string;
  text?: string;
  image_url?: VisionImageUrl;

  constructor(type: string, text?: string, image_url?: VisionImageUrl) {
    this.type = type;
    if (text) this.text = text;
    if (image_url) this.image_url = image_url;
  }
}


