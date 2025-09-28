import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'job_page_viewmodel.dart';

class JobPageView extends StackedView<JobPageViewModel> {
  const JobPageView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    JobPageViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0),
        child: const Center(child: Text("JobPageView")),
      ),
    );
  }

  @override
  JobPageViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      JobPageViewModel();
}
