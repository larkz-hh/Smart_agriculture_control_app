import http from '@ohos.net.http';
import App from '@system.app';
import { AppConfig } from '../config/AppConfig';
import {NewsItem, NewsResponse} from '../model/NewsModel';



export class NewsService {
  private static readonly API_KEY = AppConfig.API_KEY_NEWS;
  private static readonly API_URL = `https://apis.tianapi.com/nongye/index?key=${NewsService.API_KEY}&num=10&form=1`;

  //获取新闻列表
  static async getAgricultureNews(): Promise<NewsItem[]> {
    let httpRequest = http.createHttp();
    try {
      let response = await httpRequest.request(NewsService.API_URL, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      if (response.responseCode === 200) {
        let rawData = response.result as string;
        console.info('【新闻接口返回数据】:', rawData);
        let resData: NewsResponse = JSON.parse(response.result as string);
        if (resData.code === 200 && resData.result && resData.result.list) {
          return resData.result.list;
        }else {
          console.error('【新闻接口业务报错】:', resData.msg, '状态码:', resData.code);
        }
      }
      return [];
    } catch (err) {
      console.error('获取新闻失败', JSON.stringify(err));
      return [];
    } finally {
      httpRequest.destroy();
    }
  }
}

export { NewsItem };
