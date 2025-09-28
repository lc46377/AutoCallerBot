import 'package:agent_frontend/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:agent_frontend/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:agent_frontend/ui/views/home/home_view.dart';
import 'package:agent_frontend/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:agent_frontend/ui/views/login/login_view.dart';
import 'package:agent_frontend/ui/views/sign_up/sign_up_view.dart';
import 'package:agent_frontend/ui/views/job_page/job_page_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: SignUpView),
    MaterialRoute(page: JobPageView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
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
