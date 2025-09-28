import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'chatpage_viewmodel.dart';

class ChatpageView extends StackedView<ChatpageViewModel> {
  const ChatpageView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    ChatpageViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0),
        child: const Center(child: Text("ChatpageView")),
      ),
    );
  }

  @override
  ChatpageViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      ChatpageViewModel();
}
