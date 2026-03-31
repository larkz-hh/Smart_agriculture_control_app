import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { WeatherInfo } from '../model/WeatherModel';
import { AiService } from '../services/ai/AIService';
import { NewsItem, NewsService } from '../services/news/NewsService';

export class HomeViewModel {
  /**
   * 加载农业新闻
   */
  static async loadNews(): Promise<NewsItem[]> {
    try {
      let latestNews = await NewsService.getAgricultureNews();
      return latestNews || [];
    } catch (error) {
      console.error('获取新闻失败', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 获取本地天气（包含定位权限请求与逆地理编码）
   */
  static async getLocalWeather(context: common.UIAbilityContext): Promise<WeatherInfo | null> {
    let finalLocationName = '桂林市(默认)';
    let atManager = abilityAccessCtrl.createAtManager();

    try {
      // 向用户请求定位权限
      let authResult = await atManager.requestPermissionsFromUser(context, [
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION'
      ]);

      // 同意了权限
      if (authResult.authResults[0] === 0) {
        let location = await geoLocationManager.getCurrentLocation();
        try {
          // 逆地理编码
          let reverseRequest: geoLocationManager.ReverseGeoCodeRequest = {
            latitude: location.latitude,
            longitude: location.longitude,
            maxItems: 1
          };
          let placeList = await geoLocationManager.getAddressesFromLocation(reverseRequest);
          if (placeList && placeList.length > 0) {
            let place = placeList[0];
            let prov = place.administrativeArea ? place.administrativeArea : '';
            let city = place.locality ? place.locality : '';
            let dist = place.subLocality ? place.subLocality : '';
            finalLocationName = `${prov}${city}${dist}`;
            if (!finalLocationName) {
              finalLocationName = place.placeName ? place.placeName : '未知位置';
            }
          }
        } catch (e) {
          console.error('逆地理编码失败，使用经纬度代替');
          finalLocationName = `经度${location.longitude.toFixed(1)},纬度${location.latitude.toFixed(1)}`;
        }
      }
    } catch (error) {
      console.error('定位或权限请求失败:', JSON.stringify(error));
    }

    // 获取并返回天气
    return await AiService.getWeatherData(finalLocationName);
  }
}