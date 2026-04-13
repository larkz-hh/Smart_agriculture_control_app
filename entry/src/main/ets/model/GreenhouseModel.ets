export class GreenhouseModel {
  id?: number;
  name: string = '';
  deviceId: string = '';
  crop: string = '';
  stage: number = -1; // -1:未设置, 0:育苗, 1:生长, 2:开花, 3:结果
  camUrl?: string = '';
  coverImage?: string = ''; // 面图片沙箱路径
}