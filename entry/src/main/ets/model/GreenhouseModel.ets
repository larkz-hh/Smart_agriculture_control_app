export class GreenhouseModel {
  id?: number;
  name: string = '';
  deviceId: string = '';
  crop: string = '';
  stage: number = -1; // -1:未设置, 0:育苗, 1:生长, 2:开花, 3:结果
  camUrl?: string = '';
  coverImage?: string = ''; // 面图片沙箱路径
  thresholdTemp: number = 32;
  thresholdHumi: number = 45;
  thresholdLight: number = 500;
  thresholdSoil: number = 20;
  thresholdCO2: number = 1000;
}