import http from '@ohos.net.http';
import { IotConfig } from '../../config/IotConfig';

//  IoT 影子数据解析类
export class ShadowProperties {
  Temperature: number = 0;
  Humidity: number = 0;
  Light: number = 0;
  SoilMoisture: number = 0;
  CO2: number = 0;
  TempThreshold: number = 0;
  HumiThreshold: number = 0;
  LightThreshold: number = 0;
  SoilThreshold: number = 0;
  CO2Threshold: number = 0;
  PumpStatus: string = '';
  FanStatus: string = '';
  LedStatus: string = '';
  Mode: string = '';
  GrowthStage: string = '';
  HumidifierStatus: string = '';
}//

export class ShadowReported {
  properties?: ShadowProperties;
}

export class ShadowData {
  reported?: ShadowReported;
}

export class DeviceShadowResponse {
  device_id?: string;
  shadow?: ShadowData[];
}

export class ShadowResult {
  code: number = 0;
  data?: ShadowProperties;
}

// Token 返回解析类
export class IamTokenInfo {
  expires_at?: string;
}
export class IamTokenResponse {
  token?: IamTokenInfo;
}

// 鉴权请求参数的实体类
class IamDomain { name: string = ''; }
class IamUser {
  domain: IamDomain = new IamDomain();
  name: string = '';
  password: string = '';
}
class IamPassword { user: IamUser = new IamUser(); }
class IamIdentity {
  methods: string[] = ['password'];
  password: IamPassword = new IamPassword();
}
class IamProject { name: string = ''; }
class IamScope { project: IamProject = new IamProject(); }
class IamAuth {
  identity: IamIdentity = new IamIdentity();
  scope: IamScope = new IamScope();
}
class IamAuthRequest {
  auth: IamAuth = new IamAuth();
}

// 下发命令的 Body 结构定义
export class DeviceCommandBody {
  service_id: string = 'Agriculture';
  command_name: string = '';
  paras: Object = new Object();
}

// 核心服务类
export class IotService {
  private static readonly IAM_API_URL = 'https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens';
  private static readonly IOT_SHADOW_URL = `https://b6c2a407d5.st1.iotda-app.cn-south-1.myhuaweicloud.com/v5/iot/${IotConfig.PROJECT_ID}/devices/%s/shadow?service_id=Agriculture`;

  // 提取设备命令下发的基础 URL
  private static readonly IOT_COMMAND_URL = `https://b6c2a407d5.st1.iotda-app.cn-south-1.myhuaweicloud.com/v5/iot/${IotConfig.PROJECT_ID}/devices/%s/commands`;

  private static cachedToken: string = '';
  private static tokenExpireTime: number = 0;

  private static async getValidToken(): Promise<string | null> {
    let now = Date.now();
    if (IotService.cachedToken && IotService.tokenExpireTime > now + 300000) {
      return IotService.cachedToken;
    }
    let token = await IotService.fetchNewToken();
    if (token) {
      IotService.cachedToken = token;
    }
    return token;
  }

  private static async fetchNewToken(): Promise<string | null> {
    let httpRequest = http.createHttp();
    let reqBody = new IamAuthRequest();
    reqBody.auth.identity.password.user.domain.name = IotConfig.DOMAIN_NAME;
    reqBody.auth.identity.password.user.name = IotConfig.USERNAME;
    reqBody.auth.identity.password.user.password = IotConfig.PASSWORD;
    reqBody.auth.scope.project.name = IotConfig.PROJECT_NAME;

    let headers: Record<string, string> = { 'Content-Type': 'application/json' };

    try {
      let response = await httpRequest.request(IotService.IAM_API_URL, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(reqBody),
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode === 201) {
        let resHeaders = response.header as Record<string, string>;
        let token = resHeaders['X-Subject-Token'] || resHeaders['x-subject-token'];

        let resObj = JSON.parse(response.result as string) as IamTokenResponse;
        if (resObj.token && resObj.token.expires_at) {
          IotService.tokenExpireTime = new Date(resObj.token.expires_at).getTime();
        } else {
          IotService.tokenExpireTime = Date.now() + 12 * 60 * 60 * 1000;
        }
        return token || null;
      }
    } catch (err) {
      console.error('获取华为云Token失败:', JSON.stringify(err));
    } finally {
      httpRequest.destroy();
    }
    return null;
  }

  /**
   * 下发设备命令 (ArkTS 强类型实现)
   */
  static async sendCommand(deviceId: string, commandName: string, paras: Object): Promise<boolean> {
    let token = await IotService.getValidToken();
    if (!token) {
      return false;
    }

    let httpRequest = http.createHttp();
    let url = IotService.IOT_COMMAND_URL.replace('%s', deviceId);

    // 组装发送结构体
    let reqBody = new DeviceCommandBody();
    reqBody.command_name = commandName;
    reqBody.paras = paras;

    let reqHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      'X-Auth-Token': token,
      'Instance-Id': IotConfig.INSTANCE_ID
    };

    try {
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: reqHeaders,
        extraData: JSON.stringify(reqBody),
        connectTimeout: 5000,
        // 因为平台可能会在设备不在线时最多等待20秒，这里设为22秒保证能接住平台的超时回复
        readTimeout: 22000
      });

      if (response.responseCode === 200) {
        return true;
      } else {
        console.error(`下发命令[${commandName}]报错:`, response.responseCode.toString(), typeof response.result === 'string' ? response.result : JSON.stringify(response.result));
        return false;
      }
    } catch (err) {
      console.error(`下发命令[${commandName}]网络异常:`, JSON.stringify(err));
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 获取设备影子数据
   */
  static async getDeviceShadow(deviceId: string): Promise<ShadowResult> {
    let result = new ShadowResult();
    let token = await IotService.getValidToken();

    if (!token) {
      result.code = 401;
      return result;
    }

    let httpRequest = http.createHttp();
    let url = IotService.IOT_SHADOW_URL.replace('%s', deviceId);

    let reqHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      'X-Auth-Token': token,
      'Instance-Id': IotConfig.INSTANCE_ID
    };

    try {
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: reqHeaders,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      result.code = response.responseCode;

      if (response.responseCode === 200) {
        let resultStr = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);

        try {
          let jsonObj = JSON.parse(resultStr) as DeviceShadowResponse;

          if (jsonObj && jsonObj.shadow && jsonObj.shadow.length > 0) {
            let properties = jsonObj.shadow[0].reported?.properties;

            if (properties) {
              let sp = new ShadowProperties();

              sp.Temperature = properties.Temperature ?? 0;
              sp.Humidity = properties.Humidity ?? 0;
              sp.Light = properties.Light ?? 0;
              sp.SoilMoisture = properties.SoilMoisture ?? 0;
              sp.CO2 = properties.CO2 ?? 0;

              sp.TempThreshold = properties.TempThreshold ?? 32;
              sp.HumiThreshold = properties.HumiThreshold ?? 45;
              sp.LightThreshold = properties.LightThreshold ?? 500;
              sp.SoilThreshold = properties.SoilThreshold ?? 20;
              sp.CO2Threshold = properties.CO2Threshold ?? 1000;

              sp.PumpStatus = properties.PumpStatus ?? 'OFF';
              sp.FanStatus = properties.FanStatus ?? 'OFF';
              sp.LedStatus = properties.LedStatus ?? 'OFF';
              sp.HumidifierStatus=properties.HumidifierStatus??'OFF';
              sp.Mode = properties.Mode ?? 'manual';
              sp.GrowthStage = properties.GrowthStage ?? '';

              result.data = sp;
            }
          }
        } catch (parseErr) {}

      }
    } catch (err) {
      result.code = 500;
    } finally {
      httpRequest.destroy();
    }

    return result;
  }
}