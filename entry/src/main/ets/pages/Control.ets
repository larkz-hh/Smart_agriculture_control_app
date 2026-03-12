
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

  build() {
    Column() {
      Column() {
        Text('xxxxx')
          .fontSize(16)
          .fontColor('#999')
      }
      .width('100%')
      .height(200)
      .backgroundColor('#E8F5E9')
      .justifyContent(FlexAlign.Center)

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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}