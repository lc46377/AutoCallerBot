import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../models/call_log.dart';
import '../../../services/api_service.dart';
import 'package:stacked_services/stacked_services.dart';

class HomepageViewModel extends BaseViewModel {
  final ApiService _api = locator<ApiService>();
  final NavigationService _nav = locator<NavigationService>();

  List<CallLog> logs = const [];

  Future<void> fetchLogs() async {
    setBusy(true);
    try {
      logs = await _api.fetchCallLogs();
    } finally {
      setBusy(false);
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchLogs();

  Future<void> startNewTask() async {
    await _nav.navigateToChatpageView();
  }
}
