// 发送给接口的消息体
export class ApiMessage {
  role: string;
  content: string;

  constructor(role: string, content: string) {
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