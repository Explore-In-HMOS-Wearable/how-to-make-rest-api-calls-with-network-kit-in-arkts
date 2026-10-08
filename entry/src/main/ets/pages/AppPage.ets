import { ApiViewModel } from '../viewmodel/ApiViewModel';
import { DemoUiState, CallStatus } from '../viewmodel/DemoUiState';

@Component
export struct AppPage {
  @State private ui: DemoUiState = {
    status: CallStatus.IDLE,
    lastAction: '',
    statusCode: -1,
    resultText: ''
  };
  private viewModel: ApiViewModel = new ApiViewModel((state: DemoUiState) => {
    this.ui = state;
  });

  build() {
    Scroll() {
      Column({ space: 6 }) {
        Text('Network Kit REST')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 2 })

        Button('GET')
          .type(ButtonType.Capsule)
          .width('78%')
          .height(34)
          .fontSize(14)
          .onClick(() => this.viewModel.runGet())
        Button('POST')
          .type(ButtonType.Capsule)
          .width('78%')
          .height(34)
          .fontSize(14)
          .onClick(() => this.viewModel.runPost())
        Button('PUT')
          .type(ButtonType.Capsule)
          .width('78%')
          .height(34)
          .fontSize(14)
          .onClick(() => this.viewModel.runPut())
        Button('DELETE')
          .type(ButtonType.Capsule)
          .width('78%')
          .height(34)
          .fontSize(14)
          .onClick(() => this.viewModel.runDelete())
        Button('Force Error')
          .type(ButtonType.Capsule)
          .width('78%')
          .height(34)
          .fontSize(14)
          .backgroundColor(Color.Orange)
          .onClick(() => this.viewModel.runForceError())

        Divider().width('66%').margin({ top: 4, bottom: 4 })

        this.resultArea()
      }
      .width('100%')
      .padding({
        top: 28,
        bottom: 28,
        left: 8,
        right: 8
      })
      .alignItems(HorizontalAlign.Center)
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }

  @Builder
  resultArea() {
    if (this.ui.status === CallStatus.LOADING) {
      LoadingProgress()
        .width(28)
        .height(28)
    } else if (this.ui.status === CallStatus.SUCCESS || this.ui.status === CallStatus.ERROR) {
      Column({ space: 3 }) {
        Text(this.ui.lastAction)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
        Text(this.statusLine())
          .fontSize(11)
          .fontColor(this.ui.status === CallStatus.ERROR ? Color.Red : Color.Green)
        Text(this.ui.resultText)
          .fontSize(10)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Center)
      }
      .width('82%')
      .alignItems(HorizontalAlign.Center)
    }
  }

  private statusLine(): string {
    if (this.ui.statusCode >= 0) {
      return `Status: ${this.ui.statusCode}`;
    }
    return this.ui.status === CallStatus.ERROR ? 'Failed' : '';
  }
}
