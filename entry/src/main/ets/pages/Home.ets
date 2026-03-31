import { NewsItem } from '../services/news/NewsService';
import emitter from '@ohos.events.emitter';
import { common } from '@kit.AbilityKit';
import { HomeViewModel } from '../viewmodel/HomeViewModel';
import { WeatherInfo } from '../model/WeatherModel';

@Component
export struct Home {

  pathStack?: NavPathStack;
  @StorageLink('homeNewsCache') newsList: NewsItem[] = [];
  @State isLoading: boolean = false;

  @StorageLink('homeWeatherCache') weatherData: WeatherInfo | undefined | null = undefined;
  @State isWeatherLoading: boolean = false;

  aboutToAppear() {
    this.loadNewsData();
    this.initWeatherData();
  }

  // 加载新闻
  async loadNewsData() {
    if (this.newsList.length === 0) {
      this.isLoading = true;
    }
    let latestNews = await HomeViewModel.loadNews();
    if (latestNews && latestNews.length > 0) {
      this.newsList = latestNews;
    }
    this.isLoading = false;
  }

  // 初始化天气
  async initWeatherData() {
    //静默刷新
    if (!this.weatherData) {
      this.isWeatherLoading = true;
    }
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let aiWeather = await HomeViewModel.getLocalWeather(context);
      if (aiWeather) {
        this.weatherData = aiWeather;
      }
    } catch (error) {
      console.error('天气初始化失败，请打手机开位置权限:', JSON.stringify(error));
    } finally {
      this.isWeatherLoading = false;
    }
  }

  @Builder WeatherDetailItem(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(12).fontColor('#666')
      Text(value).fontSize(13).fontColor('#333').fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  // 天气预报区
  @Builder WeatherCard() {
    Column() {
      if (this.isWeatherLoading) {
        //加载中状态
        LoadingProgress().width(30).height(30).margin({ top: 20, bottom: 20 })
        Text('加载当地气象数据中...').fontSize(12).fontColor('#999')
      } else if (this.weatherData) {
        //动态数据渲染
        Row() {
          Text(`${this.weatherData.location}`)
            .fontSize(14).fontColor('#333').fontWeight(FontWeight.Medium)
          Blank()
          Text(`${this.weatherData.condition}`)
            .fontSize(14).fontColor('#00B96B').fontWeight(FontWeight.Bold)
        }.width('100%')

        Row() {
          Text(`${this.weatherData.currentTemp}°C`)
            .fontSize(36).fontWeight(FontWeight.Bold).fontColor('#333')
          Text(`最低 ${this.weatherData.lowTemp}°C / 最高 ${this.weatherData.highTemp}°C`)
            .fontSize(12).fontColor('#666').margin({ left: 12, top: 12 })
        }
        .width('100%').margin({ top: 10, bottom: 15 }).alignItems(VerticalAlign.Bottom)

        Row() {
          this.WeatherDetailItem('降水', this.weatherData.precipitation)
          Divider().vertical(true).height(20).color('#E0E0E0')
          this.WeatherDetailItem('空气湿度', this.weatherData.humidity)
          Divider().vertical(true).height(20).color('#E0E0E0')
          this.WeatherDetailItem('风速风向', this.weatherData.wind)
          Divider().vertical(true).height(20).color('#E0E0E0')
          this.WeatherDetailItem('光照', this.weatherData.light)
        }
        .width('100%').padding({ top: 12 }).border({ width: { top: 1 }, color: '#F0F0F0' })
      } else {
        Text('天气初始化失败，请打手机开位置权限').fontSize(14).fontColor('#999').margin({ top: 20, bottom: 20 })
      }
    }
    .width('92%')
    .constraintSize({ minHeight: 140 })
    .justifyContent(FlexAlign.Center)
    .padding(15)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
    .margin({ bottom: 15 })
  }

  // 金刚区
  @Builder QuickEntryItem(title: string, iconUrl: ResourceStr, onClickAction: () => void) {
    Column({ space: 8 }) {
      Image(iconUrl)
        .width(40)
        .height(40)
        .objectFit(ImageFit.Contain)

      Text(title)
        .fontSize(14)
        .fontColor('#333')
        .fontWeight(FontWeight.Medium)
    }
    .layoutWeight(1)
    .onClick(() => onClickAction())
  }


  build() {
    Column() {
      Column() {
        Row() {
          Column() {
            Text('智慧农业工作台')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
            Text('随时掌握农场动态，科学种植')
              .fontSize(12)
              .fontColor('#666')
              .margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start)
          Blank()
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 15, bottom: 15 })

        this.WeatherCard()

        // 快捷导航(金刚区)
        Row() {
          this.QuickEntryItem('植物百科', $r('app.media.plants_icon'), () => {
            if (this.pathStack) {
              this.pathStack.pushPathByName('Plants', null);
            }
          })

          this.QuickEntryItem('种植记录', $r('app.media.record_icon'), () => {
            this.pathStack?.pushPathByName('RecordList',null)
          })

          this.QuickEntryItem('添加设备', $r('app.media.device_add_icon'), () => {
            console.info('点击了添加设备');
          })

          this.QuickEntryItem('拍照识病', $r('app.media.diagnosis_icon'), () => {
            // 发送事件1001,通知Layout切换到Chat页面
            emitter.emit({ eventId: 1001 });
            //延迟 200毫秒发送事件1002,给系统一点时间把Chat页面渲染出来，再拉起相机
            setTimeout(() => {
              emitter.emit({ eventId: 1002 });
            }, 200);
          })
        }
        .width('92%')
        .padding({ top: 20, bottom: 20 })
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
        .margin({ bottom: 20 })
      }
      .width('100%')
      .backgroundColor('#E8F5E9')
      .alignItems(HorizontalAlign.Center)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])


      // 新闻列表
      Column() {
        Text('农业资讯')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .padding({ left: 15, top: 15, bottom: 10 })

        if (this.isLoading) {
          Text('加载中...').margin({ top: 50 }).fontColor('#999')
        } else if (this.newsList.length === 0) {
          Text('暂无农业资讯数据').margin({ top: 50 }).fontColor('#999')
        }else {
          List({ space: 15 }) {
            ForEach(this.newsList, (item: NewsItem) => {
              ListItem() {
                Row({ space: 10 }) {
                  Column({ space: 8 }) {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Row() {
                      Text(item.source).fontSize(12).fontColor('#999')
                      Blank()
                      Text(item.ctime).fontSize(12).fontColor('#999')
                    }.width('100%')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  if(item.picUrl){
                    Image(item.picUrl ? item.picUrl : $r('app.media.app_icon'))
                      .width(100)
                      .height(70)
                      .borderRadius(8)
                      .objectFit(ImageFit.Cover)
                      .backgroundColor('#F0F0F0')
                  }
                }
                .width('100%')
                .padding({ left: 15, right: 15 })
              }
              .onClick(() => {
                if (this.pathStack) {
                  this.pathStack.pushPathByName('NewsDetail', item.url);
                }
              })
            })
          }
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: '#F5F5F5', startMargin: 15, endMargin: 15 })
        }
      }
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}