import 'package:flutter_test/flutter_test.dart';
import 'package:house_vision/core/constants/app_strings.dart';
import 'package:house_vision/data/repositories/auth_repository_impl.dart';
import 'package:house_vision/data/repositories/project_repository_impl.dart';
import 'package:house_vision/domain/repositories/auth_repository.dart';
import 'package:house_vision/domain/repositories/project_repository.dart';
import 'package:house_vision/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App smoke test - verifies LoginScreen renders', (WidgetTester tester) async {
    final authRepo = AuthRepositoryImpl();
    final projectRepo = ProjectRepositoryImpl();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: authRepo),
          Provider<ProjectRepository>.value(value: projectRepo),
        ],
        child: const HouseVisionApp(),
      ),
    );

    // Verify brand header and tagline render
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.appTagline), findsOneWidget);
    expect(find.text('Sign In & Choose Role'), findsOneWidget);

    // Verify quick persona buttons render
    expect(find.text('Homeowner'), findsOneWidget);
    expect(find.text('Constructor'), findsOneWidget);
  });
}
