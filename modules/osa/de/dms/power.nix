{ delib, ... }:
delib.module {
  name = "osa.de.dms";

  myconfig.ifEnabled.osa.de.dms.settings = {
    acLockTimeout = 600;
    acMonitorTimeout = 300;
    acSuspendBehavior = 2;
    acSuspendTimeout = 1800;
    batteryLockTimeout = 300;
    batteryMonitorTimeout = 120;
    batterySuspendBehavior = 2;
    batterySuspendTimeout = 600;
    lockBeforeSuspend = true;
  };
}
