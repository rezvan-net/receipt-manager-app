import 'package:moor_flutter/moor_flutter.dart';

part 'receipt_database.g.dart';

class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get receiptTotal => text()();

  TextColumn get shopName => text()();

  TextColumn get category => text()();

  DateTimeColumn get receiptDate => dateTime().nullable()();
}

@UseMoor(tables: [Receipts], daos: [ReceiptDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(FlutterQueryExecutor.inDatabaseFolder(
            path: "db.sql", logStatements: true));

  int get schemaVersion => 1;
}

@UseDao(tables: [Receipts])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  final AppDatabase db;

  ReceiptDao(this.db) : super(db);

  Future<List<Receipt>> getReceipts() => select(receipts).get();

  Stream<List<Receipt>> watchReceipts() => select(receipts).watch();

  Future insertReceipt(Receipt receipt) => into(receipts).insert(receipt);

  Future updateReceipt(Receipt receipt) => update(receipts).replace(receipt);

  Future deleteReceipt(Receipt receipt) => delete(receipts).delete(receipt);
}