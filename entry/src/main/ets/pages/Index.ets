import { common, Permissions } from '@kit.AbilityKit';
import { PermissionsUtil } from '../utils/PermissionsUtil';
import { AppPage } from './AppPage';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const permissions: Permissions[] = ['ohos.permission.INTERNET', 'ohos.permission.GET_NETWORK_INFO'];
    PermissionsUtil.request(context, permissions);
  }

  build() {
    Column() {
      AppPage()
    }
    .width('100%')
    .height('100%')
  }
}
