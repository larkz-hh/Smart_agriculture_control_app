import { NewsItem, NewsService } from '../services/NewsService';

@Component
export struct Home {

  pathStack?: NavPathStack;

  @State newsList: NewsItem[] = [];
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadNews();
  }

  async loadNews() {
    this.isLoading = true;
    this.newsList = await NewsService.getAgricultureNews();
    this.isLoading = false;
  }

  // 🌟 新增：天气底部小参数的通用 Builder
  @Builder WeatherDetailItem(label: string, value: string) {
    Column({ space: 4 }) {
      Text(label).fontSize(12).fontColor('#666')
      Text(value).fontSize(13).fontColor('#333').fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  // 🌟 新增：天气预报区 Builder (静态写死数据)
  @Builder WeatherCard() {
    Column() {
      // 第一行：地点和天气状态
      Row() {
        Text('📍 杭州市·西湖区智慧农场')
          .fontSize(14)
          .fontColor('#333')
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('🌤 晴转多云')
          .fontSize(14)
          .fontColor('#00B96B')
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')

      // 第二行：主温度和最高最低温
      Row() {
        Text('26°C')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Text('最高 28°C / 最低 18°C')
          .fontSize(12)
          .fontColor('#666')
          .margin({ left: 12, top: 12 })
      }
      .width('100%')
      .margin({ top: 10, bottom: 15 })
      .alignItems(VerticalAlign.Bottom)

      // 第三行：详细农业气象参数 (降水、湿度、风、光照)
      Row() {
        this.WeatherDetailItem('降水', '0 mm')
        // 分割线
        Divider().vertical(true).height(20).color('#E0E0E0')
        this.WeatherDetailItem('空气湿度', '45%')
        Divider().vertical(true).height(20).color('#E0E0E0')
        this.WeatherDetailItem('风速风向', '东南风 3级')
        Divider().vertical(true).height(20).color('#E0E0E0')
        this.WeatherDetailItem('光照', '12000 Lx')
      }
      .width('100%')
      .padding({ top: 12 })
      .border({ width: { top: 1 }, color: '#F0F0F0' }) // 顶部加个极细的分割线
    }
    .width('92%')
    .padding(15)
    // 使用带有轻微渐变或纯白的背景，增加层次感
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 10, color: '#0A000000', offsetY: 4 })
    .margin({ bottom: 15 })
  }

  // 金刚区 Item Builder
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
      // --- 上半部分：标题 + 天气 + 金刚区 ---
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

        // 🌟 插入天气预报卡片
        this.WeatherCard()

        // 快捷导航 (金刚区)
        Row() {
          this.QuickEntryItem('植物百科', $r('app.media.app_icon'), () => {
            if (this.pathStack) {
              this.pathStack.pushPathByName('Plants', null);
            }
          })

          this.QuickEntryItem('种植记录', $r('app.media.app_icon'), () => {
            console.info('点击了种植记录');
          })

          this.QuickEntryItem('添加设备', $r('app.media.app_icon'), () => {
            console.info('点击了添加设备');
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


      // --- 下半部分：新闻列表 ---
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
          // 这里的 layoutWeight(1) 会让资讯列表吃掉屏幕上所有剩下的空间
          // 因为上半部分变高了，所以资讯列表的比例自然就被压缩减小了
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: '#F5F5F5', startMargin: 15, endMargin: 15 })
        }
      }
      .layoutWeight(1)
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 24, topRight: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}