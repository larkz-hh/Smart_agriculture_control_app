import { AuthService } from '../services/auth/AuthService';

export class RegisterResult {
  success: boolean;
  message: string;

  constructor(success: boolean, message: string) {
    this.success = success;
    this.message = message;
  }
}


export class LoginResult {
  success: boolean;
  message: string;
  token: string;

  constructor(success: boolean, message: string, token: string = '') {
    this.success = success;
    this.message = message;
    this.token = token;
  }
}

export class AuthViewModel {
  /**
   * 密码格式校验
   */
  static validatePassword(pwd: string, email: string): string {
    if (pwd.length < 8) return '密码长度至少为8位';
    if (pwd === email) return '密码不可与邮箱地址相同';
    let typeCount = 0;
    if (/[A-Z]/.test(pwd)) typeCount++; //大写
    if (/[a-z]/.test(pwd)) typeCount++; //小写
    if (/[0-9]/.test(pwd)) typeCount++; //数字
    if (/[^A-Za-z0-9]/.test(pwd)) typeCount++; // 符号
    if (typeCount < 2) return '密码需至少包含字母、数字、符号中的2种';
    return '';
  }

  /**
   * 【注册】获取验证码前置检查及发送请求
   */
  static async getVerifyCode(email: string, password: string, confirmPassword: string): Promise<string> {
    if (!email || !email.includes('@')) {
      return '请填写正确的邮箱地址';
    }
    if (!password || !confirmPassword) {
      return '请先填写并确认密码';
    }
    if (password !== confirmPassword) {
      return '两次输入密码不一致，请修改后再获取验证码';
    }

    let pwdError = AuthViewModel.validatePassword(password, email);
    if (pwdError) {
      return pwdError;
    }

    try {
      await AuthService.sendVerifyCode(email);
      return '';
    } catch (error) {
      return error instanceof Error ? error.message : '发送失败';
    }
  }

  /**
   * 【注册】操作
   */
  static async register(email: string, password: string, confirmPassword: string, verifyCode: string): Promise<RegisterResult> {
    if (!email || !password || !confirmPassword || !verifyCode) {
      return new RegisterResult(false, '请完整填写所有信息');
    }
    if (password !== confirmPassword) {
      return new RegisterResult(false, '两次密码输入不一致');
    }

    let pwdError = AuthViewModel.validatePassword(password, email);
    if (pwdError) {
      return new RegisterResult(false, pwdError);
    }

    try {
      let res = await AuthService.registerUser(email, verifyCode, password);

      if (res.ret && res.ret.code === 0) {
        return new RegisterResult(true, '注册成功，请登录账号');
      } else if (res.ret && res.ret.code === 203818130) {
        return new RegisterResult(false, '该邮箱已被注册，请直接返回登录');
      } else {
        return new RegisterResult(false, res.ret?.msg || '注册失败，请检查验证码是否正确');
      }
    } catch (error) {
      return new RegisterResult(false, error instanceof Error ? error.message : '网络异常，请重试');
    }
  }

  /**
   * 【登录】获取验证码请求
   */
  static async getLoginVerifyCode(email: string): Promise<string> {
    if (!email || !email.includes('@')) {
      return '请填写正确的邮箱地址';
    }
    try {
      await AuthService.sendVerifyCode(email);
      return ''; // 返回空字符串代表成功
    } catch (error) {
      return error instanceof Error ? error.message : '发送失败';
    }
  }
  /**
   * 【登录】操作 - 密码登录
   */
  static async loginByPassword(email: string, password: string): Promise<LoginResult> {
    if (!email || !password) {
      return new LoginResult(false, '请完整填写邮箱和密码');
    }

    try {
      let res = await AuthService.signInWithPassword(email, password);

      if (res.ret && res.ret.code === 0) {
        let token = res.accessToken?.token ? res.accessToken.token : '';
        return new LoginResult(true, '登录成功', token);
      } else if (res.ret && res.ret.code === 203818032) {
        return new LoginResult(false, '该账号尚未注册，请先注册');
      } else {
        return new LoginResult(false, res.ret?.msg || '账号或密码错误');
      }
    } catch (error) {
      return new LoginResult(false, '网络异常，请重试');
    }
  }

  /**
   * 【登录】操作
   */
  static async login(email: string, verifyCode: string): Promise<LoginResult> {
    if (!email || !verifyCode) {
      return new LoginResult(false, '请完整填写邮箱和验证码');
    }

    try {
      let res = await AuthService.signInByVerifyCode(email, verifyCode);

      if (res.ret && res.ret.code === 0) {
        let token = res.accessToken?.token ? res.accessToken.token : '';
        return new LoginResult(true, '登录成功', token);
      } else if (res.ret && res.ret.code === 203818032) {
        return new LoginResult(false, '该账号尚未注册，请先注册');
      } else {
        return new LoginResult(false, res.ret?.msg || '登录失败，请检查验证码');
      }
    } catch (error) {
      return new LoginResult(false, '网络异常，请重试');
    }
  }
}
















































