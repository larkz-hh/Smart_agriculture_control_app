import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import util from '@ohos.util';

export function resolveIP(ip:number):string{
  if(ip<0||ip>0xFFFFFFFF){
    return '0'
  }
  return (ip >>>24)+'.'+(ip >> 16 & 0xFF)+'.'+(ip >>8 &0xFF) +'.'+(ip &0xFF);
}




