export class AlertMessageModel {
  id: number = 0;
  ghId: number = 0;
  ghName: string = '';
  content: string = '';
  timestamp: number = 0;
  isRead: number = 0; // 0代表未读，1代表已读
}