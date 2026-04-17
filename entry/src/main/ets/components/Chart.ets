import { EnvRecordModel } from '../model/GreenhouseModel';

export class ChartPoint {
  x: number = 0;
  y: number = 0;
  val: number = 0;
  time: string = '';
}

@Component
export struct Chart {
  @Prop @Watch('drawChart') records: EnvRecordModel[] = [];
  @Prop @Watch('drawChart') metricType: string = 'temp';
  @Prop @Watch('drawChart') colorHex: string = '#FF6B6B';

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State canvasWidth: number = 320;
  @State canvasHeight: number = 250;
  private drawTaskId: number = -1;

  getUnit(): string {
    switch (this.metricType) {
      case 'temp': return '℃';
      case 'humi':
      case 'soil': return '%';
      case 'light': return 'Lx';
      case 'co2': return 'ppm';
      default: return '';
    }
  }


  formatTime(timestamp: number, isMultiDay: boolean): string {
    let d = new Date(timestamp);
    if (isMultiDay) {
      let mo = (d.getMonth() + 1).toString().padStart(2, '0');
      let da = d.getDate().toString().padStart(2, '0');
      return `${mo}/${da}`;
    } else {
      let hh = d.getHours();
      let mm = d.getMinutes().toString().padStart(2, '0');
      // 处理图表末尾的 24:00 边界
      if (hh === 0 && mm === '00' && new Date().getDate() !== d.getDate()) {
        return `24:00`;
      }
      return `${hh.toString().padStart(2, '0')}:${mm}`;
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(this.canvasHeight)
      .onAreaChange((oldValue, newValue) => {
        this.canvasWidth = Number(newValue.width);
        this.drawChart();
      })
  }

  drawChart() {
    clearTimeout(this.drawTaskId);
    this.drawTaskId = setTimeout(() => {
      this.executeDraw();
    }, 15);
  }

  executeDraw() {
    if (!this.ctx) return;
    let w = this.canvasWidth;
    let h = this.canvasHeight;
    this.ctx.clearRect(0, 0, w, h);

    if (!this.records || this.records.length === 0) {
      this.ctx.font = '14vp sans-serif';
      this.ctx.fillStyle = '#000000';
      this.ctx.textAlign = 'center';
      this.ctx.fillText('暂无数据，等待采集...', w / 2, h / 2);
      return;
    }

    // 判断是否跨度超过48小时（即7天模式）
    let isMultiDay = false;
    if (this.records.length > 1) {
      let diff = this.records[this.records.length - 1].timestamp - this.records[0].timestamp;
      if (diff > 48 * 3600000) isMultiDay = true;
    }

    let dataList: number[] = [];
    let timeList: string[] = [];
    this.records.forEach(r => {
      if (this.metricType === 'temp') dataList.push(r.temp);
      else if (this.metricType === 'humi') dataList.push(r.humi);
      else if (this.metricType === 'soil') dataList.push(r.soil);
      else if (this.metricType === 'light') dataList.push(r.light);
      else if (this.metricType === 'co2') dataList.push(r.co2);

      timeList.push(this.formatTime(r.timestamp, isMultiDay));
    });

    let maxVal = Math.max(...dataList);
    let minVal = Math.min(...dataList);
    let range = maxVal - minVal;
    // 如果数值完全一样，强行上下撑开空间
    if (range === 0) { maxVal += 5; minVal -= 5; range = 10; }

    maxVal = maxVal + range * 0.20;
    minVal = minVal - range * 0.15;

    let paddingLeft = 65;
    let paddingRight = 20;
    let paddingTop = 30;
    let paddingBottom = 30;

    let plotW = w - paddingLeft - paddingRight;
    let plotH = h - paddingTop - paddingBottom;
    let unit = this.getUnit();

    // ================== 画背景网格和 Y轴刻度 ==================
    this.ctx.lineWidth = 1;
    this.ctx.font = 'bold 11vp sans-serif';
    this.ctx.textAlign = 'right';
    this.ctx.textBaseline = 'middle';

    for (let i = 0; i <= 4; i++) {
      let y = paddingTop + i * (plotH / 4);
      let val = maxVal - i * ((maxVal - minVal) / 4);

      this.ctx.fillStyle = '#000000';
      // 数值很大时（比如光照）不要带小数
      let labelVal = val > 100 ? Math.round(val).toString() : val.toFixed(1);
      this.ctx.fillText(labelVal + unit, paddingLeft - 8, y);

      this.ctx.strokeStyle = '#EEEEEE';
      this.ctx.beginPath();
      this.ctx.moveTo(paddingLeft, y);
      this.ctx.lineTo(w - paddingRight, y);
      this.ctx.stroke();
    }

    // ================== 画出 X 轴和 Y 轴实线 ==================
    this.ctx.strokeStyle = '#333333';
    this.ctx.lineWidth = 1.5;
    this.ctx.beginPath();
    this.ctx.moveTo(paddingLeft, paddingTop);
    this.ctx.lineTo(paddingLeft, h - paddingBottom);
    this.ctx.lineTo(w - paddingRight, h - paddingBottom);
    this.ctx.stroke();

    let points: ChartPoint[] = [];
    for (let i = 0; i < dataList.length; i++) {
      let x = paddingLeft + (i / Math.max(1, dataList.length - 1)) * plotW;
      let y = h - paddingBottom - ((dataList[i] - minVal) / (maxVal - minVal)) * plotH;

      let pt = new ChartPoint();
      pt.x = x;
      pt.y = y;
      pt.val = dataList[i];
      pt.time = timeList[i];
      points.push(pt);
    }

    // ================== ：画 X轴 底部的时间文字 ==================
    this.ctx.fillStyle = '#000000';
    this.ctx.font = 'bold 10vp sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'top';

    // 计算刻度的步长
    let step = points.length > 10 ? Math.floor((points.length - 1) / 6) : 1;
    if (step < 1) step = 1;

    points.forEach((p, i) => {
      if (i % step === 0 || i === points.length - 1) {
        this.ctx.fillText(p.time, p.x, h - paddingBottom + 8);
        this.ctx.beginPath();
        this.ctx.moveTo(p.x, h - paddingBottom);
        this.ctx.lineTo(p.x, h - paddingBottom + 4);
        this.ctx.stroke();
      }
    });

    // ================== 画折线主体 ==================
    this.ctx.strokeStyle = this.colorHex;
    this.ctx.lineWidth = 2.5;
    this.ctx.beginPath();
    points.forEach((p, i) => {
      if (i === 0) this.ctx.moveTo(p.x, p.y);
      else this.ctx.lineTo(p.x, p.y);
    });
    this.ctx.stroke();

    // ================== 画折线上的空心小圆点和具体数值 ==================
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'bottom';
    this.ctx.font = 'bold 13vp sans-serif';

    points.forEach((p, i) => {
      // 1. 所有圆点照常画出（保持折线的节点质感）
      this.ctx.fillStyle = '#FFFFFF';
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, 4.0, 0, 2 * Math.PI);
      this.ctx.fill();

      this.ctx.strokeStyle = this.colorHex;
      this.ctx.lineWidth = 2.0;
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, 4.0, 0, 2 * Math.PI);
      this.ctx.stroke();

      // 只在有时间刻度的地方，或者是终点时，才绘制上方具体数值
      if (i % step === 0 || i === points.length - 1) {
        this.ctx.fillStyle = this.colorHex;
        let displayVal = p.val > 100 ? Math.round(p.val).toString() : p.val.toFixed(1);
        this.ctx.fillText(displayVal, p.x, p.y - 8);
      }
    });
  }
}