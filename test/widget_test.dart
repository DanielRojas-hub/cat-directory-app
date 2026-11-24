import 'package:cat_directory_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test renders root scaffold', (tester) async {
    await tester.pumpWidget(const CatDirectoryApp());
    expect(find.text('Cat Directory App'), findsOneWidget);
  });
}
