import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { cameraPicker, camera } from '@kit.CameraKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import util from '@ohos.util';

export class ImageUtil {
  /**
   * 复制系统临时图片到App沙箱，防止重启后权限丢失
   */
  static copyImageToSandbox(context: common.UIAbilityContext, uri: string): string {
    try {
      let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      let ext = uri.split('.').pop() || 'jpg';
      let fileName = util.generateRandomUUID(true) + '.' + ext;
      let sandboxPath = context.filesDir + '/' + fileName;
      fileIo.copyFileSync(file.fd, sandboxPath);
      fileIo.closeSync(file.fd);
      return 'file://' + sandboxPath;
    } catch (e) {
      console.error('拷贝图片到沙箱失败', JSON.stringify(e));
      return uri; // 失败退回原uri
    }
  }

  /**
   * 2调用系统相册选择照片，并直接存入沙箱返回永久URI
   */
  static async pickPhotoFromGallery(context: common.UIAbilityContext): Promise<string> {
    try {
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let result = await photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result && result.photoUris.length > 0) {
        return ImageUtil.copyImageToSandbox(context, result.photoUris[0]);
      }
    } catch (err) {
      console.error('选择照片失败', JSON.stringify(err));
    }
    return '';
  }

  /**
   * 调用系统相机拍照，并直接存入沙箱返回永久URI
   */
  static async takePhotoWithCamera(context: common.UIAbilityContext): Promise<string> {
    try {
      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      };
      let result = await cameraPicker.pick(context, [cameraPicker.PickerMediaType.PHOTO], pickerProfile);
      if (result && result.resultUri) {
        return ImageUtil.copyImageToSandbox(context, result.resultUri);
      }
    } catch (err) {
      console.error('拍照失败', JSON.stringify(err));
    }
    return '';
  }

  /**
   * 4读取图片转为 Base64字符串（供AI接口使用）
   */
  static imageUriToBase64(uri: string): string {
    try {
      let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      let stat = fileIo.statSync(file.fd);
      let buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file.fd);

      let base64Helper = new util.Base64Helper();
      let base64Str = base64Helper.encodeToStringSync(new Uint8Array(buffer));
      return 'data:image/jpeg;base64,' + base64Str;
    } catch (e) {
      console.error('图片转换Base64失败:', JSON.stringify(e));
      return '';
    }
  }
}