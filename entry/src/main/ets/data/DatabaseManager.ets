import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { MessageModel } from '../model/MessageModel';

/**
 * 聊天记录与聊天消息关系型数据库
 */
// 会话列表
export interface SessionItem {
  id: number;
  title: string;
  timestamp: number;
}

export class DatabaseManager {
  private static rdbStore: relationalStore.RdbStore | null = null;

  // 初始化数据库和建表
  static async init(context: common.UIAbilityContext | common.Context) {
    if (DatabaseManager.rdbStore) return;
    const config: relationalStore.StoreConfig = {
      name: 'AgriChat.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    const createSessionTable = `CREATE TABLE IF NOT EXISTS Session (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      timestamp INTEGER
    )`;
    const createMessageTable = `CREATE TABLE IF NOT EXISTS Message (
      id TEXT PRIMARY KEY,
      sessionId INTEGER,
      role TEXT,
      content TEXT,
      imageUri TEXT,
      imageBase64 TEXT,
      timestamp INTEGER
    )`;

    try {
      DatabaseManager.rdbStore = await relationalStore.getRdbStore(context, config);
      await DatabaseManager.rdbStore.executeSql(createSessionTable);
      await DatabaseManager.rdbStore.executeSql(createMessageTable);
      console.info('数据库初始化成功');
    } catch (e) {
      console.error('数据库初始化失败:', JSON.stringify(e));
    }
  }

  // 新建会话
  static async insertSession(title: string, timestamp: number): Promise<number> {
    if (!DatabaseManager.rdbStore) return -1;
    let bucket: relationalStore.ValuesBucket = { title: title, timestamp: timestamp };
    try {
      return await DatabaseManager.rdbStore.insert('Session', bucket);
    } catch (e) {
      console.error('会话插入失败:', JSON.stringify(e));
      return -2;
    }
  }

  //更新会话标题
  static async updateSessionTitle(sessionId: number, newTitle: string) {
    if (!DatabaseManager.rdbStore) return;
    let bucket: relationalStore.ValuesBucket = { title: newTitle };
    let predicates = new relationalStore.RdbPredicates('Session');
    predicates.equalTo('id', sessionId);
    try {
      await DatabaseManager.rdbStore.update(bucket, predicates);
    } catch (e) {
      console.error('标题更新失败:', JSON.stringify(e));
    }
  }

  //保存消息
  static async insertMessage(msg: MessageModel, sessionId: number) {
    if (!DatabaseManager.rdbStore) return;
    try {
      let bucket: relationalStore.ValuesBucket = {
        id: msg.id,
        sessionId: sessionId,
        role: msg.role,
        content: msg.content,
        imageUri: msg.imageUri || '',
        imageBase64: msg.imageBase64 || '',
        timestamp: msg.timestamp
      };
      await DatabaseManager.rdbStore.insert('Message', bucket);

      let sessionBucket: relationalStore.ValuesBucket = { timestamp: msg.timestamp };
      let predicates = new relationalStore.RdbPredicates('Session');
      predicates.equalTo('id', sessionId);
      //更新会话时间
      await DatabaseManager.rdbStore.update(sessionBucket, predicates);
    } catch (e) {
      console.error('插入消息到数据库失败:', JSON.stringify(e));
    }
  }

  //获取历史会话列表(按时间倒序)
  static async getSessionList(): Promise<SessionItem[]> {
    if (!DatabaseManager.rdbStore) return [];
    try {
      let predicates = new relationalStore.RdbPredicates('Session');
      predicates.orderByDesc('timestamp'); //最新会话的在最上面

      let resultSet = await DatabaseManager.rdbStore.query(predicates, ['id', 'title', 'timestamp']);
      let list: SessionItem[] = [];
      while (resultSet.goToNextRow()) {
        list.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          title: resultSet.getString(resultSet.getColumnIndex('title')),
          timestamp: resultSet.getLong(resultSet.getColumnIndex('timestamp'))
        });
      }
      resultSet.close();
      return list;

    }catch (e) {
      console.error('获取历史会话失败:', JSON.stringify(e));
      return [];
    }

  }

  //获取某个会话的所有聊天记录
  static async getMessagesBySession(sessionId: number): Promise<MessageModel[]> {
    try {
      if (!DatabaseManager.rdbStore) return [];
      let predicates = new relationalStore.RdbPredicates('Message');
      predicates.equalTo('sessionId', sessionId);
      predicates.orderByAsc('timestamp'); // 聊天记录按时间正序

      let resultSet = await DatabaseManager.rdbStore.query(predicates);
      let list: MessageModel[] = [];
      while (resultSet.goToNextRow()) {
        let role = resultSet.getString(resultSet.getColumnIndex('role')) as 'user' | 'assistant' | 'system';
        let content = resultSet.getString(resultSet.getColumnIndex('content'));
        let msg = new MessageModel(role, content);
        msg.id = resultSet.getString(resultSet.getColumnIndex('id'));
        msg.sessionId = sessionId;
        msg.timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));

        let imgUri = resultSet.getString(resultSet.getColumnIndex('imageUri'));
        let imgBase64 = resultSet.getString(resultSet.getColumnIndex('imageBase64'));
        if (imgUri) msg.imageUri = imgUri;
        if (imgBase64) msg.imageBase64 = imgBase64;

        list.push(msg);
      }
      resultSet.close();
      return list;
    }catch (e) {
      console.error('获取聊天失败:', JSON.stringify(e));
      return [];
    }

  }

  // 删除会话及底下的所有消息
  static async deleteSession(sessionId: number) {
    if (!DatabaseManager.rdbStore) return
    try {
      let msgPredicates = new relationalStore.RdbPredicates('Message');
      msgPredicates.equalTo('sessionId', sessionId);
      await DatabaseManager.rdbStore.delete(msgPredicates);

      //删会话
      let sessionPredicates = new relationalStore.RdbPredicates('Session');
      sessionPredicates.equalTo('id', sessionId);
      await DatabaseManager.rdbStore.delete(sessionPredicates);
    }catch (e){
      console.error('删除会话与消息失败:', JSON.stringify(e));
    }
    //删消息

  }
}