import http from '@ohos.net.http';
import { AuthConfig } from '../../config/AuthConfig';

interface RetMsg {
  code: number;
  msg: string;
}

interface TokenRsp {
  access_token?: string;
  expires_in?: number;
  ret?: RetMsg;
  error?: string;
  error_description?: string;
}

interface VerifyCodeRsp {
  ret?: RetMsg;
}

export interface RegisterRsp {
  ret?: RetMsg;
}

export interface AccessTokenObj {
  token: string;
  validPeriod: number;
}

export interface RefreshTokenObj {
  token: string;
  validPeriod: number;
}

export interface SignInRsp {
  ret?: RetMsg;
  accessToken?: AccessTokenObj;
  refreshToken?: RefreshTokenObj;
}

const HOST = 'https://connect-drcn.dbankcloud.cn';

export class AuthService {
  // 缓存 Client Token 和过期时间
  private static cachedToken: string = '';
  private static tokenExpireTime: number = 0;

  /**
   * 获取客户端 Token
   */
  static async getAccessToken(): Promise<string> {
    const now = Date.now();
    // 提前5分钟判定过期
    if (AuthService.cachedToken && AuthService.tokenExpireTime > now + 300000) {
      return AuthService.cachedToken;
    }

    let httpRequest = http.createHttp();
    try {
      let response = await httpRequest.request(
        `${HOST}/agc/apigw/oauth2/v1/token`,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: {
            useJwt: 1,
            grant_type: 'client_credentials',
            client_id: AuthConfig.CLIENT_ID,
            client_secret: AuthConfig.CLIENT_SECRET
          },
          expectDataType: http.HttpDataType.STRING
        }
      );

      //console.info('【获取Token返回】:', response.result);

      if (response.responseCode === 200) {
        let resData = JSON.parse(response.result as string) as TokenRsp;
        if (resData.access_token && resData.expires_in) {
          AuthService.cachedToken = resData.access_token;
          AuthService.tokenExpireTime = now + (resData.expires_in * 1000);
          return AuthService.cachedToken;
        } else {

          let errMsg = resData.ret?.msg || resData.error_description || resData.error || '未返回 access_token';
          throw new Error(`华为鉴权拒绝: ${errMsg}`);
        }
      }
      throw new Error(`HTTP异常码: ${response.responseCode}`);
    } catch (err) {
      let msg = err instanceof Error ? err.message : '获取Token发生未知异常';
      console.error('【请求Token异常】:', msg);
      throw new Error(msg);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 发送邮箱验证码 (用于注册)
   */
  static async sendVerifyCode(email: string): Promise<boolean> {
    let token = await AuthService.getAccessToken();
    let httpRequest = http.createHttp();

    try {
      let response = await httpRequest.request(
        `${HOST}/agc/apigw/oauth2/third/v1/verify-code?productId=${AuthConfig.PRODUCT_ID}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json;charset=utf-8',
            'client_id': AuthConfig.CLIENT_ID,
            'Authorization': `Bearer ${token}`
          },
          extraData: {
            email: email,
            action: 1001, // 1001表示注册或登录
            lang: 'zh_CN',
            sendInterval: 30
          },
          expectDataType: http.HttpDataType.STRING
        }
      );

      //console.info('【发送验证码返回】:', response.result);
      let resData = JSON.parse(response.result as string) as VerifyCodeRsp;

      if (resData.ret && resData.ret.code === 0) {
        return true;
      } else {
        throw new Error(resData.ret?.msg || '发送验证码失败');
      }
    } catch (err) {
      let errorMessage = err instanceof Error ? err.message : '发送验证码网络异常';
      throw new Error(errorMessage);
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 注册用户 (包含密码)
   */
  static async registerUser(email: string, verifyCode: string, password: string): Promise<RegisterRsp> {
    let token = await AuthService.getAccessToken();
    let httpRequest = http.createHttp();

    try {
      let response = await httpRequest.request(
        `${HOST}/agc/apigw/oauth2/third/v1/user-register?productId=${AuthConfig.PRODUCT_ID}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json;charset=utf-8',
            'client_id': AuthConfig.CLIENT_ID,
            'Authorization': `Bearer ${token}`
          },
          extraData: {
            email: email,
            verifyCode: verifyCode,
            password: password,
            useJwt: 1
          },
          expectDataType: http.HttpDataType.STRING
        }
      );

      console.info('【注册接口返回】:', response.result);
      let resData = JSON.parse(response.result as string) as RegisterRsp;
      return resData;
    } catch (err) {
      throw new Error('网络请求异常');
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 账号密码登录
   */
  static async signInWithPassword(email: string, password: string): Promise<SignInRsp> {
    let token = await AuthService.getAccessToken();
    let httpRequest = http.createHttp();

    try {
      let response = await httpRequest.request(
        `${HOST}/agc/apigw/oauth2/third/v1/user-signin?productId=${AuthConfig.PRODUCT_ID}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json;charset=utf-8',
            'client_id': AuthConfig.CLIENT_ID,
            'Authorization': `Bearer ${token}`
          },
          extraData: {
            provider: 12, // 邮箱
            token: email,
            password: password, // 直接使用密码登录
            autoCreateUser: 0,
            useJwt: 1
          },
          expectDataType: http.HttpDataType.STRING
        }
      );

      console.info('【密码登录返回】:', response.result);
      let resData = JSON.parse(response.result as string) as SignInRsp;
      return resData;
    } catch (err) {
      throw new Error('登录请求异常');
    } finally {
      httpRequest.destroy();
    }
  }
  /**
   * 验证码登录
   */
  static async signInByVerifyCode(email: string, verifyCode: string): Promise<SignInRsp> {
    let token = await AuthService.getAccessToken();
    let httpRequest = http.createHttp();

    try {
      let response = await httpRequest.request(
        `${HOST}/agc/apigw/oauth2/third/v1/user-signin?productId=${AuthConfig.PRODUCT_ID}`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json;charset=utf-8',
            'client_id': AuthConfig.CLIENT_ID,
            'Authorization': `Bearer ${token}`
          },
          extraData: {
            provider: 12, // 12代表邮箱
            token: email,
            extraData: JSON.stringify({ "verifyCode": verifyCode }),
            autoCreateUser: 0,
            useJwt: 1
          }
        }
      );

      let resData = JSON.parse(response.result as string) as SignInRsp;
      return resData;
    } catch (err) {
      throw new Error('登录请求异常');
    } finally {
      httpRequest.destroy();
    }
  }
}