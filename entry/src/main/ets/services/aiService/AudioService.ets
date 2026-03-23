import audio from '@ohos.multimedia.audio';
import { fileIo } from '@kit.CoreFileKit';
import util from '@ohos.util';


export class AudioRecordResult {
  base64Str: string;
  length: number;

  constructor(base64Str: string, length: number) {
    this.base64Str = base64Str;
    this.length = length;
  }
}

export class AudioService {
  private static audioCapturer: audio.AudioCapturer | null = null;
  private static recordFilePath: string = '';
  private static fileFd: number = -1;
  private static isRecording: boolean = false;//防并发锁

  //初始化并开始录音
  static async startRecording(context: Context): Promise<void> {
    if (AudioService.isRecording) {
      console.warn('录音正在进行中，请勿重复调用');
      return;
    }
    try {
      //准备文件存放路径(缓存目录)
      AudioService.recordFilePath = context.cacheDir + '/temp_record.pcm';
      // 同步打开文件
      let file = fileIo.openSync(AudioService.recordFilePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      //保存文件描述符
      AudioService.fileFd = file.fd;

      //配置符合百度 API 要求的录音参数
      let audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000, // 16K
        channels: audio.AudioChannel.CHANNEL_1, // 单声道
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 16bit
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // PCM裸流
      };
      let audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };
      let audioCapturerOptions: audio.AudioCapturerOptions = {
        streamInfo: audioStreamInfo,
        capturerInfo: audioCapturerInfo
      };

      AudioService.audioCapturer = await audio.createAudioCapturer(audioCapturerOptions);

      // 监听录音数据，写入文件
      AudioService.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (AudioService.fileFd !== -1) {
          //执行同步写入
          fileIo.writeSync(AudioService.fileFd, buffer);
        }
      });

      await AudioService.audioCapturer.start();
    } catch (e) {
      console.error('开始录音失败:', JSON.stringify(e));
      AudioService.isRecording = false; // 重置状态
      if (AudioService.fileFd !== -1) {
        try {
          fileIo.closeSync(AudioService.fileFd);
        } catch (closeErr) {
          console.error('关闭文件失败:', closeErr);
        }
        AudioService.fileFd = -1;
      }
    }
  }


  static async stopRecordingAndGetBase64(): Promise<AudioRecordResult> {
    try {
      if (AudioService.audioCapturer) {
        await AudioService.audioCapturer.stop();
        await AudioService.audioCapturer.release();
        AudioService.audioCapturer = null;
      }
      if (AudioService.fileFd !== -1) {
        fileIo.closeSync(AudioService.fileFd);
        AudioService.fileFd = -1;
      }
      AudioService.isRecording = false;

      // 读取文件并转为 Base64
      let stat = fileIo.statSync(AudioService.recordFilePath);
      let fileLen = stat.size;

      if (fileLen === 0) return new AudioRecordResult('', 0);

      let file = fileIo.openSync(AudioService.recordFilePath, fileIo.OpenMode.READ_ONLY);
      let buffer = new ArrayBuffer(fileLen);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file.fd);

      let base64Helper = new util.Base64Helper();
      let base64Str = base64Helper.encodeToStringSync(new Uint8Array(buffer));
      return new AudioRecordResult(base64Str, fileLen);

    } catch (e) {
      console.error('停止录音并转换失败:', JSON.stringify(e));
      AudioService.isRecording = false;
      return new AudioRecordResult('', 0);
    }
  }
}