export interface NewsItem {
  id: string;
  url: string;
  ctime: string;
  title: string;
  picUrl: string;
  source: string;
  description: string;
}

interface NewsResult {
  list: NewsItem[];
  allnum: number;//结果数
  curpage: number;//当前页
}

export interface NewsResponse {
  code: number;
  msg: string;
  result: NewsResult;
}