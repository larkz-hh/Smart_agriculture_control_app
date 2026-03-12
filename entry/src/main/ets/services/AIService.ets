import http from '@ohos.net.http';
import util from '@ohos.util';
import { AppConfig } from '../config/AppConfig';
import { ApiMessage, StreamResponseModel } from '../model/AiApiModel';
import { MessageModel } from '../model/MessageModel';

interface Thinking{
  "type": string ;
}

export class AiService {
  private static readonly API_KEY = AppConfig.API_KEY;
  private static readonly API_URL = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  private static readonly MODEL_NAME = 'doubao-seed-2-0-pro-260215';

  /**
   * 发送流式对话请求
   * @param chatHistory 当前的对话历史
   * @param onChunk 每次收到字时的回调
   * @param onFinish 对话结束时的回调
   * @param onError 发生错误时的回调
   */
  static async sendStreamChat(
    chatHistory: MessageModel[],
    isDeepThinking: boolean,
    onChunk: (text: string) => void,
    onFinish: () => void,
    onError: (err: string) => void
  ) {
    let apiMessages: ApiMessage[] = [];
    apiMessages.push(new ApiMessage('system', '你是一个智慧农业助手，懂得许多农业知识，旨在为广大农户科普农业知识和技术性指导'));

    for (let i = 0; i < chatHistory.length; i++) {
      let msg = chatHistory[i];
      if (msg.content) {
        apiMessages.push(new ApiMessage(msg.role, msg.content));
      }
    }

    let httpRequest = http.createHttp();
    let buffer = '';
    //监听流式返回
    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      // let textDecoder = new util.TextDecoder('utf-8');
      // buffer += textDecoder.decodeWithStream(new Uint8Array(data));
      let textDecoder = util.TextDecoder.create('utf-8');
      buffer += textDecoder.decodeToString(new Uint8Array(data), { stream: true });

      let lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (let line of lines) {
        line = line.trim();
        if (line.startsWith('data: ')) {
          let jsonStr = line.substring(6).trim();

          if (jsonStr === '[DONE]') {
            onFinish();
            continue;
          }

          if (!jsonStr) continue;

          try {
            let parsedObj = JSON.parse(jsonStr) as StreamResponseModel;
            if (parsedObj.choices && parsedObj.choices.length > 0) {
              let deltaContent = parsedObj.choices[0].delta?.content;
              if (deltaContent) {
                onChunk(deltaContent); // 把拿到的字传给前端 UI
              }
            }
          } catch (e) {
            console.error('JSON解析流式数据失败', jsonStr);
          }
        }
      }
    });

    httpRequest.on('dataEnd', () => {
      onFinish();
      httpRequest.destroy();
    });

    //发起请求
    try {
      await httpRequest.requestInStream(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AiService.API_KEY}`
        },
        extraData: JSON.stringify({
          model: AiService.MODEL_NAME,
          messages: apiMessages,
          stream: true,
          thinking: ({ "type": isDeepThinking ? 'enabled' : 'disabled' } as Thinking)
        }),
        connectTimeout: 60000,
        readTimeout: 60000
      });
    } catch (err) {
      console.error('网络请求失败');
      onError('网络请求失败，请稍后重试。');
    }
  }
}