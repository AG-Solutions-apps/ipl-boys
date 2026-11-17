import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:iplfpl_frontend/main.dart';
import 'package:iplfpl_frontend/services/auth_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const IplFplApp(),
      ),
    );
    expect(find.byType(IplFplApp), findsOneWidget);
  });
}
