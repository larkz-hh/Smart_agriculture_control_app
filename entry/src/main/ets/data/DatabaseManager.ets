import relationalStore from '@ohos.data.relationalStore';
import { common } from '@kit.AbilityKit';
import { MessageModel } from '../model/MessageModel';
import { PlantRecord, RecordGroup } from '../model/RecordModel';

export interface SessionItem {
  id: number;
  title: string;
  timestamp: number;
}

export class DatabaseManager {
  private static rdbStore: relationalStore.RdbStore | null = null;

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
    const createRecordGroupTable = `CREATE TABLE IF NOT EXISTS RecordGroup (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT, updateTime INTEGER)`;

    const createPlantRecordTable = `CREATE TABLE IF NOT EXISTS PlantRecord (
      id TEXT PRIMARY KEY,
      groupId INTEGER,
      imageUri TEXT,
      description TEXT,
      timestamp INTEGER
      )`;

    try {
      DatabaseManager.rdbStore = await relationalStore.getRdbStore(context, config);
      await DatabaseManager.rdbStore.executeSql(createSessionTable);
      await DatabaseManager.rdbStore.executeSql(createMessageTable);
      await DatabaseManager.rdbStore.executeSql(createRecordGroupTable);
      await DatabaseManager.rdbStore.executeSql(createPlantRecordTable)
      console.info('数据库初始化成功');
    } catch (e) {
      console.error('数据库初始化失败:', JSON.stringify(e));
    }
  }

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

  static async insertMessage(msg: MessageModel, sessionId: number) {
    if (!DatabaseManager.rdbStore) return;
    try {
      let bucket: relationalStore.ValuesBucket = {
        id: msg.id,
        sessionId: sessionId,
        role: msg.role,
        content: msg.content,
        imageUri: msg.imageUri || '',
        imageBase64: '',
        timestamp: msg.timestamp
      };
      await DatabaseManager.rdbStore.insert('Message', bucket);

      let sessionBucket: relationalStore.ValuesBucket = { timestamp: msg.timestamp };
      let predicates = new relationalStore.RdbPredicates('Session');
      predicates.equalTo('id', sessionId);
      await DatabaseManager.rdbStore.update(sessionBucket, predicates);
    } catch (e) {
      console.error('插入消息到数据库失败:', JSON.stringify(e));
    }
  }

  static async getSessionList(): Promise<SessionItem[]> {
    if (!DatabaseManager.rdbStore) return [];
    try {
      let predicates = new relationalStore.RdbPredicates('Session');
      predicates.orderByDesc('timestamp');

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

  static async getMessagesBySession(sessionId: number): Promise<MessageModel[]> {
    try {
      if (!DatabaseManager.rdbStore) return [];
      let predicates = new relationalStore.RdbPredicates('Message');
      predicates.equalTo('sessionId', sessionId);
      predicates.orderByAsc('timestamp');

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

  static async deleteSession(sessionId: number) {
    if (!DatabaseManager.rdbStore) return
    try {
      let msgPredicates = new relationalStore.RdbPredicates('Message');
      msgPredicates.equalTo('sessionId', sessionId);
      await DatabaseManager.rdbStore.delete(msgPredicates);

      let sessionPredicates = new relationalStore.RdbPredicates('Session');
      sessionPredicates.equalTo('id', sessionId);
      await DatabaseManager.rdbStore.delete(sessionPredicates);
    }catch (e){
      console.error('删除会话与消息失败:', JSON.stringify(e));
    }
  }

  static async insertRecordGroup(name: string): Promise<void> {
    if (!DatabaseManager.rdbStore) return;
    let bucket: relationalStore.ValuesBucket = { name: name, updateTime: Date.now() };
    await DatabaseManager.rdbStore.insert('RecordGroup', bucket);
  }

  static async getRecordGroups(): Promise<RecordGroup[]> {
    if (!DatabaseManager.rdbStore) return [];
    let predicates = new relationalStore.RdbPredicates('RecordGroup');
    predicates.orderByDesc('updateTime');
    let rs = await DatabaseManager.rdbStore.query(predicates);
    let list: RecordGroup[] = [];
    while (rs.goToNextRow()) {
      let group = new RecordGroup();
      group.id = rs.getLong(rs.getColumnIndex('id'));
      group.name = rs.getString(rs.getColumnIndex('name'));
      group.updateTime = rs.getLong(rs.getColumnIndex('updateTime'));
      list.push(group);
    }
    rs.close();
    return list;
  }

  static async insertPlantRecord(record: PlantRecord): Promise<void> {
    if (!DatabaseManager.rdbStore) return;
    let bucket: relationalStore.ValuesBucket = {
      id: record.id, groupId: record.groupId, imageUri: record.imageUri, description: record.desc, timestamp: record.timestamp
    };
    await DatabaseManager.rdbStore.insert('PlantRecord', bucket);

    let groupBucket: relationalStore.ValuesBucket = { updateTime: record.timestamp };
    let groupPred = new relationalStore.RdbPredicates('RecordGroup');
    groupPred.equalTo('id', record.groupId);
    await DatabaseManager.rdbStore.update(groupBucket, groupPred);
  }

  static async getRecordsByGroupId(groupId: number): Promise<PlantRecord[]> {
    if (!DatabaseManager.rdbStore) return [];
    let predicates = new relationalStore.RdbPredicates('PlantRecord');
    predicates.equalTo('groupId', groupId);
    predicates.orderByDesc('timestamp');
    let rs = await DatabaseManager.rdbStore.query(predicates);
    let list: PlantRecord[] = [];
    while (rs.goToNextRow()) {
      let record = new PlantRecord();
      record.id = rs.getString(rs.getColumnIndex('id'));
      record.groupId = rs.getLong(rs.getColumnIndex('groupId'));
      record.imageUri = rs.getString(rs.getColumnIndex('imageUri'));
      record.desc = rs.getString(rs.getColumnIndex('description'));
      record.timestamp = rs.getLong(rs.getColumnIndex('timestamp'));
      list.push(record);
    }
    rs.close();
    return list;
  }

  static async deletePlantRecord(recordId: string) {
    if (!DatabaseManager.rdbStore) return;
    let predicates = new relationalStore.RdbPredicates('PlantRecord');
    predicates.equalTo('id', recordId);
    await DatabaseManager.rdbStore.delete(predicates);
  }

  static async deleteRecordGroup(groupId: number) {
    if (!DatabaseManager.rdbStore) return;
    try {
      let recordPredicates = new relationalStore.RdbPredicates('PlantRecord');
      recordPredicates.equalTo('groupId', groupId);
      await DatabaseManager.rdbStore.delete(recordPredicates);

      let groupPredicates = new relationalStore.RdbPredicates('RecordGroup');
      groupPredicates.equalTo('id', groupId);
      await DatabaseManager.rdbStore.delete(groupPredicates);
    } catch (e) {
      console.error('删除分组及其记录失败:', JSON.stringify(e));
    }
  }
}