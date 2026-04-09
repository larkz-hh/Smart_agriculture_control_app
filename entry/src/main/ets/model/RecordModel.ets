import util from '@ohos.util';

// 种植分组模型
export class RecordGroup {
  id: number = 0;
  name: string = '';
  updateTime: number = 0;
}

//单条种植记录模型
export class PlantRecord {
  id: string;
  groupId: number = 0;
  imageUri: string = '';
  desc: string = '';
  timestamp: number;

  constructor() {
    this.id = util.generateRandomUUID(true);
    this.timestamp = Date.now();
  }

  getFormattedTime(): string {
    const d = new Date(this.timestamp);
    const year = d.getFullYear();
    const month = (d.getMonth() + 1).toString().padStart(2, '0');
    const day = d.getDate().toString().padStart(2, '0');
    const hours = d.getHours().toString().padStart(2, '0');
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }
}