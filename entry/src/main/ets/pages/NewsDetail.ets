import web_webview from '@ohos.web.webview';

@Builder
export function NewsDetailBuilder(name: string, param: Object) {
  NewsDetail()
}

@Component
export struct NewsDetail {
  pathStack: NavPathStack = new NavPathStack();
  webviewController: web_webview.WebviewController = new web_webview.WebviewController();

  @State targetUrl: string = '';

  build() {
    NavDestination() {
      Column() {
        if (this.targetUrl) {
          Web({
            src: this.targetUrl,
            controller: this.webviewController
          })
            .width('100%')
            .height('100%')
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('资讯详情')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.targetUrl = context.pathInfo.param as string;
    })
  }
}