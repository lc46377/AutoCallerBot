import 'package:agent_frontend/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:agent_frontend/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:agent_frontend/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:agent_frontend/ui/views/signup/signup_view.dart';
import 'package:agent_frontend/ui/views/homepage/homepage_view.dart';
import 'package:agent_frontend/ui/views/chatpage/chatpage_view.dart';
import 'package:agent_frontend/services/api_service.dart';
import 'package:agent_frontend/ui/views/login/login_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: StartupView),
    MaterialRoute(page: SignupView),
    MaterialRoute(page: HomepageView),
    MaterialRoute(page: ChatpageView),
    MaterialRoute(page: LoginView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: ApiService),
// @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}