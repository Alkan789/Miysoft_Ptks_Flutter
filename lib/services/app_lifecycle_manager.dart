import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eyyubiye_personel_takip/services/workmanager_service.dart'; // WorkManager servisinizin yolu

class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  const AppLifecycleManager({Key? key, required this.child}) : super(key: key);

  @override
  _AppLifecycleManagerState createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _setIsInForeground(true);
      _updateWorkManagerBasedOnPauseStatus();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setIsInForeground(false);
      // Opsiyonel: Arka plana geçerken WorkManager görevlerini iptal etmek isterseniz:
      // WorkmanagerService.cancelAllTasks();
    }
  }

  Future<void> _setIsInForeground(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInForeground', value);
    debugPrint("[AppLifecycleManager] isInForeground=$value");
  }

  /// Veritabanı (ör. SharedPreferences) üzerinden pause kaydı varsa,
  /// WorkManager görevlerini iptal ediyoruz; yoksa yeniden planlıyoruz.
  Future<void> _updateWorkManagerBasedOnPauseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // 'pauseActive' true ise pause durumunda demektir.
    bool pauseActive = prefs.getBool('pauseActive') ?? false;
    if (pauseActive) {
      debugPrint("[AppLifecycleManager] Pause durumu aktif, WorkManager görevleri iptal ediliyor.");
      await WorkmanagerService.cancelAllTasks();
    } else {
      debugPrint("[AppLifecycleManager] Pause durumu yok, WorkManager görevleri yeniden planlanıyor.");
      await WorkmanagerService.schedulePeriodicTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
