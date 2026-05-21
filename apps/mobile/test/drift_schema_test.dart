import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/data/db/drift/app_database.dart';

void main() {
  test('drift schema opens with phase 7 local tables', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 5);
    expect(await db.select(db.weeklyInsightsLocal).get(), isEmpty);
    expect(await db.select(db.userFoodDefaultsLocal).get(), isEmpty);
    expect(await db.select(db.outboxCommands).get(), isEmpty);
  });
}
