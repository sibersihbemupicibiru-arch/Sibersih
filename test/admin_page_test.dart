import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibersih/pages/admin/admin_layout.dart';

void main() {
  testWidgets('Admin stat card renders title and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminStatCard(
            title: 'Pengguna',
            value: '42',
            icon: Icons.group_rounded,
            accentColor: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('PENGGUNA'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });
}
