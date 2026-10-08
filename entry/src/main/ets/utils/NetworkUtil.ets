import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'NetworkKitDemo';

export class NetworkUtil {
  static isNetworkAvailable(): boolean {
    try {
      const netHandle: connection.NetHandle = connection.getDefaultNetSync();
      // netId 0 means there is no default network at all.
      if (!netHandle || netHandle.netId === 0) {
        return false;
      }
      const caps: connection.NetCapabilities = connection.getNetCapabilitiesSync(netHandle);
      const netCaps: connection.NetCap[] = caps.networkCap ?? [];
      // VALIDATED means the system confirmed real internet access, not just a link.
      return netCaps.includes(connection.NetCap.NET_CAPABILITY_VALIDATED);
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, TAG, `network check failed: ${e.code} ${e.message}`);
      return false;
    }
  }
}
