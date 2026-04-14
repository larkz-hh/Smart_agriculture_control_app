import notificationManager from '@ohos.notificationManager';
import { DatabaseManager } from '../../data/DatabaseManager';
import { AlertMessageModel } from '../../model/AlertMessageModel';
import { IotService } from '../iot/IotService';
import { common } from '@kit.AbilityKit';

export class AlertService {
  private static timer: number = -1;
  // 用于防抖，避免同一大棚频繁报警 id 与时间间隔
  private static lastAlertMap: Map<number, number> = new Map();
  //申请通知权限
  static requestNotificationPermission(context: common.UIAbilityContext) {
    notificationManager.requestEnableNotification(context).then(() => {
      console.info('通知权限已授权');
    }).catch((err: Error) => {
      console.error('获取通知权限失败:', err.message);
    });
  }

  static startPolling() {
    // 防止重复启动
    if (AlertService.timer !== -1) return;

    // 每 15 秒轮询一次
    AlertService.timer = setInterval(async () => {
      let isEnabled = AppStorage.get<boolean>('isAlertEnabled');
      if (isEnabled === false) {
        return; // 如果用户在设置里关掉了预警，直接跳过本次轮询
      }
      let ghList = await DatabaseManager.getGreenhouseList();
      for (let gh of ghList) {
        if (!gh.deviceId || !gh.id) continue;
        //获取设备实时数据
        let res = await IotService.getDeviceShadow(gh.deviceId);
        if (res.code === 200 && res.data) {
          let data = res.data;
          let alerts: string[] = [];

          // 5项指标的逻辑判断
          //超过温度阈值
          if (data.Temperature >= gh.thresholdTemp) {
            alerts.push(`温度(${data.Temperature}℃) 超上限(${gh.thresholdTemp}℃)`);
          }
          //超过空气湿度阈值
          if (data.Humidity >= gh.thresholdHumi) {
            alerts.push(`空气湿度(${data.Humidity}%) 超上限(${gh.thresholdHumi}%)`);
          }
          //超过二氧化碳浓度阈值
          if (data.CO2 >= gh.thresholdCO2) {
            alerts.push(`CO2(${data.CO2}ppm) 超上限(${gh.thresholdCO2}ppm)`);
          }
          //低于土壤湿度阈值
          if (data.SoilMoisture <= gh.thresholdSoil) {
            alerts.push(`土壤湿度(${data.SoilMoisture}%) 低于下限(${gh.thresholdSoil}%)`);
          }
          //低于光照阈值
          if (data.Light <= gh.thresholdLight) {
            alerts.push(`光照(${data.Light}Lx) 低于下限(${gh.thresholdLight}Lx)`);
          }
          //预警处理
          if (alerts.length > 0) {
            let now = Date.now();
            let lastTime = AlertService.lastAlertMap.get(gh.id) || 0;

            // 防抖， 冷却时间： 30秒，不重复报警
            if (now - lastTime > 30000) {
              //拼接预警内容
              let alertContent = alerts.join('；');
              // 创建预警记录对象
              let newAlert = new AlertMessageModel();
              newAlert.ghId = gh.id;
              newAlert.ghName = gh.name;
              newAlert.content = alertContent;
              newAlert.timestamp = now;
              //数据库存储
              await DatabaseManager.insertAlert(newAlert);
              // 通知全局变量，更新首页的红点图标
              AppStorage.setOrCreate('hasNewAlert', true);
              //发送系统通知
              AlertService.sendSystemNotification(gh.name, alertContent);
              // 更新防抖时间戳
              AlertService.lastAlertMap.set(gh.id, now);
            }
          }
        }
      }
    }, 15000);
  }

  private static sendSystemNotification(title: string, text: string) {
    let notificationRequest: notificationManager.NotificationRequest = {
      id: Math.floor(Math.random() * 10000),/// 随机ID防重复
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: `⚠️ ${title} 预警`,
          text: text//通知内容
        }
      }
    };
    // 发布通知（失败时打印错误
    notificationManager.publish(notificationRequest).catch((err: Error) => {
      console.error('通知发送失败:', err.message);
    });
  }
}