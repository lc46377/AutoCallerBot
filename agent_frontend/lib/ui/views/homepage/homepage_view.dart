import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'homepage_viewmodel.dart';
import '../../common/app_theme.dart';
import '../../widgets/call_log_card.dart';

class HomepageView extends StackedView<HomepageViewModel> {
  const HomepageView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    HomepageViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fetch')),
      body: Container(
        decoration: gradientBackground(context),
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: viewModel.isBusy
              ? const Center(child: CircularProgressIndicator())
              : (viewModel.logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4)),
                          const SizedBox(height: 8),
                          Text(
                            'No call history yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start a new task to see it here',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: viewModel.logs.length,
                      itemBuilder: (context, index) {
                        final log = viewModel.logs[index];
                        return CallLogCard(
                          log: log,
                          onTap: () {},
                        );
                      },
                    )),
        ),
      ),
      floatingActionButton: Hero(
        tag: 'fab-new-task',
        child: FloatingActionButton.extended(
          onPressed: viewModel.startNewTask,
          icon: const Icon(Icons.add_comment_rounded),
          label: const Text('New Task'),
        ),
      ),
    );
  }

  @override
  HomepageViewModel viewModelBuilder(
    BuildContext context,
  ) =>
      HomepageViewModel();

  @override
  void onViewModelReady(HomepageViewModel viewModel) {
    viewModel.fetchLogs();
  }
}
