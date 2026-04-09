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
}

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


// 核心服务类
export class IotService {
  private static readonly IAM_API_URL = 'https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens';
  private static readonly IOT_SHADOW_URL = `https://b6c2a407d5.st1.iotda-app.cn-south-1.myhuaweicloud.com/v5/iot/${IotConfig.PROJECT_ID}/devices/%s/shadow?service_id=Agriculture`;

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
   * 获取设备影子数据
   */
  static async getDeviceShadow(deviceId: string): Promise<ShadowResult> {
    let result = new ShadowResult();
    let token = await IotService.getValidToken();

    if (!token) {
      console.error('========== 错误：无法获取有效的鉴权 Token ==========');
      result.code = 401;
      return result;
    }

    console.info('========== 1. 成功准备好 Token ==========\n', token);

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
      console.info('========== 2. 华为云接口返回状态码 ==========\n', response.responseCode.toString());

      if (response.responseCode === 200) {
        let resultStr = typeof response.result === 'string' ? response.result : JSON.stringify(response.result);

        console.info('========== 3. 华为云返回的原始JSON字符串 ==========\n', resultStr);

        try {
          let jsonObj = JSON.parse(resultStr) as DeviceShadowResponse;

          if (jsonObj && jsonObj.shadow && jsonObj.shadow.length > 0) {
            let properties = jsonObj.shadow[0].reported?.properties;

            if (properties) {
              console.info('========== 4. 成功提取到 properties 对象 ==========\n', JSON.stringify(properties));

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
              sp.Mode = properties.Mode ?? 'manual';
              sp.GrowthStage = properties.GrowthStage ?? '';

              result.data = sp;
            } else {
              console.error('========== 错误：解析到了 shadow，但没有 reported.properties ==========');
            }
          } else {
            console.error('========== 错误：解析出的 shadow 为空或不存在 ==========');
          }
        } catch (parseErr) {
          console.error('========== 错误：JSON.parse 抛出异常 ==========\n', JSON.stringify(parseErr));
        }

      } else {
        console.error('========== 错误：接口请求失败，返回结果如下 ==========\n', typeof response.result === 'string' ? response.result : JSON.stringify(response.result));
      }
    } catch (err) {
      console.error('========== 错误：获取设备影子网络请求抛出异常 ==========\n', JSON.stringify(err));
      result.code = 500;
    } finally {
      httpRequest.destroy();
    }

    return result;
  }
}