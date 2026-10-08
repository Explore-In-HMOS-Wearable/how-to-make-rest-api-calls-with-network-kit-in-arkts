import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'NetworkKitDemo';

export class PermissionsUtil {
  static async request(context: common.UIAbilityContext, permissions: Permissions[]): Promise<boolean> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const authResults: number[] = result.authResults;
      const granted: boolean = authResults.length > 0 && authResults.every((v: number) => v === 0);
      hilog.info(DOMAIN, TAG, `permissions granted: ${granted}`);
      return granted;
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, `request permissions failed: ${e.code} ${e.message}`);
      return false;
    }
  }
}
