import 'package:flutter_test/flutter_test.dart';
import 'package:agent_frontend/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SignupViewModel Tests -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
