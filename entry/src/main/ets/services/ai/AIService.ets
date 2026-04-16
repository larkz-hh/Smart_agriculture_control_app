import http from '@ohos.net.http';
import util from '@ohos.util';
import { AppConfig } from '../../config/AppConfig';
import { ApiMessage, StreamResponseModel,NonStreamResponseModel, VisionContentItem,
  VisionImageUrl } from '../../model/AiApiModel';
import { MessageModel } from '../../model/MessageModel';
import { WeatherInfo } from '../../model/WeatherModel';

interface BaiduSpeechRequest {
  format: string;
  rate: number;
  dev_pid: number;
  channel: number;
  cuid: string;
  len: number;
  speech: string;
}


interface BaiduSpeechResponse {
  err_no: number;
  err_msg: string;
  result?: string[]; // 只有成功时才有这个字段
  sn?: string;
}
export interface PlantInfo {
  light: string;
  soilTemp: string;
  soilMoisture: string;
  airTemp: string;
  airMoisture: string;
  carbonDioxide: string;
  advice: string;
  durationDays: number;
}

interface Thinking{
  "type": string ;
}
interface ChatRequestBody {
  model: string;
  messages: ApiMessage[];
  stream: boolean;
  thinking?: Thinking; // 设为可选，视觉模型不传
}



export class AiService {
  private static readonly API_KEY = AppConfig.API_KEY;
  private static readonly API_URL = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  private static readonly MODEL_NAME = 'doubao-seed-2-0-pro-260215';

  /**
   * 发送流式对话请求
   * @param chatHistory 当前的对话历史
   * @param isDeepThinking 是否开启深度思考
   * @param onChunk 每次收到字时的回调
   * @param onFinish 对话结束时的回调
   * @param onError 发生错误时的回调
   */
  /**
   * 发送流式对话请求
   */
  static async sendStreamChat(
    chatHistory: MessageModel[],
    isDeepThinking: boolean,
    onChunk: (text: string) => void,
    onFinish: () => void,
    onError: (err: string) => void
  ) {
    let apiMessages: ApiMessage[] = [];
    apiMessages.push(new ApiMessage('system', '你是一个智慧农业助手。你精通各种农业知识，耐心解答，科普农业知识。如果用户发了植物照片，请帮他分析病虫害或生长状态。'));
    let hasImage = false;

    for (let i = 0; i < chatHistory.length; i++) {
      let msg = chatHistory[i];
      if (msg.imageBase64) {
        hasImage = true;
        let visionContent: VisionContentItem[] = [];
        visionContent.push(new VisionContentItem('image_url', undefined, new VisionImageUrl(msg.imageBase64)));
        if (msg.content) {
          visionContent.push(new VisionContentItem('text', msg.content));
        }
        apiMessages.push(new ApiMessage(msg.role, visionContent));
      } else {
        if (msg.content) {
          apiMessages.push(new ApiMessage(msg.role, msg.content));
        }
      }
    }

    let requestPayload: ChatRequestBody = {
      model: AiService.MODEL_NAME,
      messages: apiMessages,
      stream: true
    };
    if (!hasImage) {
      requestPayload.thinking = { type: isDeepThinking ? 'enabled' : 'disabled' };
    }

    let httpRequest = http.createHttp();
    let buffer = '';


    let isFinished = false;

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      let textDecoder = util.TextDecoder.create('utf-8');
      let newText = textDecoder.decodeToString(new Uint8Array(data), { stream: true });
      buffer += newText;

      if (buffer.includes('"error"')) {
        console.error('【AI接口报错】', buffer);
        if (!isFinished) {
          isFinished = true;
          onError('\n[系统提示：AI接口报错，可能是图片过大或网络问题]');
        }
        return;
      }

      let lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (let line of lines) {
        line = line.trim();
        if (line.startsWith('data: ')) {
          let jsonStr = line.substring(6).trim();

          if (jsonStr === '[DONE]') {

            if (!isFinished) {
              isFinished = true;
              onFinish();
            }
            continue;
          }

          if (!jsonStr) continue;

          try {
            let parsedObj = JSON.parse(jsonStr) as StreamResponseModel;
            if (parsedObj.choices && parsedObj.choices.length > 0) {
              let deltaContent = parsedObj.choices[0].delta?.content;
              if (deltaContent) {
                onChunk(deltaContent);
              }
            }
          } catch (e) {
            console.error('JSON解析流式数据失败', jsonStr);
          }
        }
      }
    });

    httpRequest.on('dataEnd', () => {

      if (!isFinished) {
        isFinished = true;
        onFinish();
      }
      httpRequest.destroy();
    });

    try {
      await httpRequest.requestInStream(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AiService.API_KEY}`
        },
        extraData: JSON.stringify(requestPayload),
        connectTimeout: 60000,
        readTimeout: 60000
      });
    } catch (err) {
      console.error('网络请求失败');
      if (!isFinished) {
        isFinished = true;
        onError('网络请求失败，请稍后重试。');
      }
    }
  }



  private static readonly BAIDU_API_KEY = AppConfig.API_KEY_BAIDU;

  /**
   * 百度语音识别接口
   * @param base64Audio 音频的 base64 字符串
   * @param audioLen 音频文件原始大小（字节数）
   */
  static async recognizeSpeech(base64Audio: string, audioLen: number): Promise<string> {
    let httpRequest = http.createHttp();
    let url = 'http://vop.baidu.com/server_api';

    let requestBody: BaiduSpeechRequest = {
      format: "pcm",
      rate: 16000,
      dev_pid: 1537,
      channel: 1,
      cuid: "harmony_agri_app",
      len: audioLen,
      speech: base64Audio
    };

    try {
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',

          'Authorization': `Bearer ${AiService.BAIDU_API_KEY}`
        },
        extraData: JSON.stringify(requestBody),
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode === 200) {
        let resObj = JSON.parse(response.result as string) as BaiduSpeechResponse;
        if (resObj.err_no === 0 && resObj.result && resObj.result.length > 0) {
          return resObj.result[0]; // 返回识别到的文字
        } else {
          console.error('语音识别报错:', resObj.err_msg);
        }
      }
    } catch (err) {
      console.error('语音识别网络请求失败:', JSON.stringify(err));
    } finally {
      httpRequest.destroy();
    }
    return ""; // 失败返回空字符串
  }

  //非流式，用于植物百科
  static async getPlantInfo(plantName: string, stage: string): Promise<PlantInfo | null> {
    let httpRequest = http.createHttp();

    let systemPrompt = `你现在是一个专业的农业环境数据API。请根据用户提供的【作物名称】和【生长时期】，严格返回该时期适宜的生长环境数据。
    警告：你必须且只能返回合法的JSON对象，绝对不要包含任何Markdown标记（如 \`\`\`json ），不要任何废话解释！
    JSON 必须包含以下7个字段：
    {
      "light": "适宜光照强度描述(最小值和最大值，单位Lx)",
      "soilTemp": "土壤适宜温度描述(最小值和最大值,单位℃)",
      "soilMoisture": "土壤适宜湿度描述(最小值和最大值)",
      "airTemp": "空气适宜温度描述(最小值和最大值，单位℃)",
      "airMoisture": "空气适宜湿度(最小值和最大值)",
      "carbonDioxide": "二氧化碳适宜浓度(最小值和最大值，单位ppm)",
      "advice": "针对该作物在此生长阶段的种植建议与注意事项，字数严格控制在30到50字左右",
      "durationDays": 15
    }
    注意：durationDays必须是纯数字，代表该生长阶段通常需要持续的天数。`   ;

    let userPrompt = `作物名称：${plantName}，生长时期：${stage}`;
    let apiMessages: ApiMessage[] = [
      new ApiMessage('system', systemPrompt),
      new ApiMessage('user', userPrompt)
    ];

    try {
      let response = await httpRequest.request(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AiService.API_KEY}`
        },
        extraData: JSON.stringify({
          model: AiService.MODEL_NAME,
          messages: apiMessages,
          stream: false,
          thinking: ({ "type": "disabled" } as Thinking)
        }),
        connectTimeout: 30000,
        readTimeout: 30000
      });

      if (response.responseCode === 200) {
        let resObj = JSON.parse(response.result as string) as NonStreamResponseModel;
        if (resObj.choices && resObj.choices.length > 0) {
          let message = resObj.choices[0].message;
          if (message && message.content) {
            let content = message.content;
            //代替可能存在的 ```json 标记
            content = content.replace(/```json/g, '').replace(/```/g, '').trim();
            let plantInfo = JSON.parse(content) as PlantInfo;
            return plantInfo;
          }
        }
      }
    } catch (err) {
      console.error('获取植物环境信息失败:', JSON.stringify(err));
    } finally {
      httpRequest.destroy();
    }
    return null;
  }
  static async generateChatTitle(firstMessage: string): Promise<string> {
    let httpRequest = http.createHttp();


    let systemPrompt = `你是一个标题生成器。请根据用户发的内容，用不超过6个汉字总结核心意思作为标题。
    要求：只能输出标题文字，绝对不要任何标点符号、解释或 Markdown 标记。`;

    try {
      let response = await httpRequest.request(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AiService.API_KEY}`
        },
        extraData: JSON.stringify({
          model: AiService.MODEL_NAME,
          messages: [
            new ApiMessage('system', systemPrompt),
            new ApiMessage('user', firstMessage)
          ],
          stream: false,
          thinking: { "type": "disabled" } as Thinking
        }),
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode === 200) {
        let resObj = JSON.parse(response.result as string) as NonStreamResponseModel;
        if (resObj.choices && resObj.choices.length > 0) {
          let message = resObj.choices[0].message;
          if (message && message.content) {
            //去除可能的换行符
            return message.content.trim().replace(/\n/g, '');
          }
        }
      }
    } catch (err) {
      console.error('生成标题失败:', err);
    } finally {
      httpRequest.destroy();
    }
    return "新聊天"; //兜底标题
  }
  static async getWeatherData(locationName: string): Promise<WeatherInfo | null> {
    let httpRequest = http.createHttp();

    // 强迫 AI 返回我们要的严格 JSON
    let systemPrompt = `你现在是一个专业的农业气象数据API。
    用户会提供一个地理位置。如果你能联网获取当前真实天气请使用真实数据；如果不能，请根据该地当前的季节和气候，模拟一份极其合理的农业天气数据。
    警告：必须且只能返回合法的JSON对象，绝对不要包含 Markdown 标记（如 \`\`\`json ），不要任何解释！
    JSON 必须严格包含以下字段：
    {
      "location": "地点名称",
      "condition": "天气状况(如:晴转多云/小雨等)",
      "currentTemp": 26,
      "highTemp": 28,
      "lowTemp": 18,
      "precipitation": "0 mm",
      "humidity": "45%",
      "wind": "东南风 3级",
      "light": "12000 Lx"
    }`;

    let userPrompt = `当前位置：${locationName}`;

    try {
      let response = await httpRequest.request(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${AiService.API_KEY}`
        },
        extraData: JSON.stringify({
          model: AiService.MODEL_NAME,
          messages: [
            new ApiMessage('system', systemPrompt),
            new ApiMessage('user', userPrompt)
          ],
          stream: false,
          thinking: { "type": "disabled" } as Thinking
        }),
        connectTimeout: 30000,
        readTimeout: 30000
      });

      if (response.responseCode === 200) {
        let resObj = JSON.parse(response.result as string) as NonStreamResponseModel;
        if (resObj.choices && resObj.choices.length > 0) {
          let message = resObj.choices[0].message;
          if (message && message.content) {
            let content = message.content.replace(/```json/g, '').replace(/```/g, '').trim();
            return JSON.parse(content) as WeatherInfo;
          }
        }
      }
    } catch (err) {
      console.error('获取天气信息失败:', JSON.stringify(err));
    } finally {
      httpRequest.destroy();
    }
    return null;
  }

}