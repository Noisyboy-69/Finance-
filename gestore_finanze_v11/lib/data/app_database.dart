
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class AppDatabase {
  AppDatabase._();
  static final instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    return openDatabase(
      join(await getDatabasesPath(), 'gestore_finanze.db'),
      version: 3,
      onCreate: (db, _) async => _schema(db),
      onUpgrade: (db, old, _) async {
        if (old < 2) {
          try { await db.execute("ALTER TABLE movements ADD COLUMN raw_text TEXT NOT NULL DEFAULT ''"); } catch (_) {}
          await db.execute('CREATE TABLE IF NOT EXISTS goals (id TEXT PRIMARY KEY,name TEXT NOT NULL,target REAL NOT NULL,current REAL NOT NULL,monthly_contribution REAL NOT NULL DEFAULT 0)');
          await db.execute('CREATE TABLE IF NOT EXISTS investments (id TEXT PRIMARY KEY,name TEXT NOT NULL,type TEXT NOT NULL,invested REAL NOT NULL,current_value REAL NOT NULL,monthly_pac REAL NOT NULL DEFAULT 0,platform TEXT)');
          await db.execute('CREATE TABLE IF NOT EXISTS merchant_rules (keyword TEXT PRIMARY KEY,category TEXT NOT NULL)');
        }
        if (old < 3) {
          await db.execute('CREATE TABLE IF NOT EXISTS app_settings (key TEXT PRIMARY KEY,value TEXT NOT NULL)');
        }
      },
    );
  }

  Future<void> _schema(Database db) async {
    await db.execute('CREATE TABLE incomes (id INTEGER PRIMARY KEY AUTOINCREMENT,year INTEGER NOT NULL,month INTEGER NOT NULL,amount REAL NOT NULL,status TEXT NOT NULL,UNIQUE(year,month))');
    await db.execute('CREATE TABLE account_status (id INTEGER PRIMARY KEY CHECK(id=1),current_balance REAL NOT NULL,overdraft_limit REAL NOT NULL)');
    await db.execute('CREATE TABLE recurring_expenses (id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,amount REAL NOT NULL,recurrence TEXT NOT NULL,category TEXT NOT NULL)');
    await db.execute('CREATE TABLE movements (id TEXT PRIMARY KEY,date TEXT NOT NULL,merchant TEXT NOT NULL,amount REAL NOT NULL,category TEXT NOT NULL,source TEXT NOT NULL,raw_text TEXT NOT NULL)');
    await db.execute('CREATE TABLE goals (id TEXT PRIMARY KEY,name TEXT NOT NULL,target REAL NOT NULL,current REAL NOT NULL,monthly_contribution REAL NOT NULL DEFAULT 0)');
    await db.execute('CREATE TABLE investments (id TEXT PRIMARY KEY,name TEXT NOT NULL,type TEXT NOT NULL,invested REAL NOT NULL,current_value REAL NOT NULL,monthly_pac REAL NOT NULL DEFAULT 0,platform TEXT)');
    await db.execute('CREATE TABLE merchant_rules (keyword TEXT PRIMARY KEY,category TEXT NOT NULL)');
    await db.execute('CREATE TABLE app_settings (key TEXT PRIMARY KEY,value TEXT NOT NULL)');
  }

  Future<void> saveIncome(MonthIncome x) async => (await database).insert('incomes', x.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<MonthIncome?> income(int y, int m) async {
    final r = await (await database).query('incomes', where: 'year=? AND month=?', whereArgs: [y, m], limit: 1);
    return r.isEmpty ? null : MonthIncome.fromMap(r.first);
  }
  Future<List<MonthIncome>> recentIncomes() async => (await database).query('incomes', orderBy: 'year DESC, month DESC', limit: 12).then((r) => r.map(MonthIncome.fromMap).toList());

  Future<void> saveAccount(CurrentAccountStatus x) async => (await database).insert('account_status', {'id':1,'current_balance':x.currentBalance,'overdraft_limit':x.overdraftLimit}, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<CurrentAccountStatus?> account() async {
    final r = await (await database).query('account_status', limit: 1);
    return r.isEmpty ? null : CurrentAccountStatus(currentBalance:(r.first['current_balance'] as num).toDouble(), overdraftLimit:(r.first['overdraft_limit'] as num).toDouble());
  }

  Future<void> addRecurring(RecurringExpense x) async => (await database).insert('recurring_expenses', x.toMap());
  Future<List<RecurringExpense>> recurring() async => (await database).query('recurring_expenses', orderBy:'id DESC').then((r) => r.map(RecurringExpense.fromMap).toList());
  Future<void> deleteRecurring(int id) async => (await database).delete('recurring_expenses', where:'id=?', whereArgs:[id]);

  Future<void> addMovement(Movement x) async => (await database).insert('movements', x.toMap(), conflictAlgorithm:ConflictAlgorithm.replace);
  Future<List<Movement>> movements({int? year, int? month}) async {
    final db = await database;
    String? where;
    List<Object?>? args;
    if (year != null && month != null) {
      where = 'date>=? AND date<?';
      args = [DateTime(year,month,1).toIso8601String(), DateTime(year,month+1,1).toIso8601String()];
    }
    final r = await db.query('movements', where:where, whereArgs:args, orderBy:'date DESC');
    return r.map(Movement.fromMap).toList();
  }
  Future<void> deleteMovement(String id) async => (await database).delete('movements', where:'id=?', whereArgs:[id]);

  Future<void> saveGoal(Goal x) async => (await database).insert('goals', x.toMap(), conflictAlgorithm:ConflictAlgorithm.replace);
  Future<List<Goal>> goals() async => (await database).query('goals', orderBy:'name').then((r) => r.map(Goal.fromMap).toList());
  Future<void> deleteGoal(String id) async => (await database).delete('goals', where:'id=?', whereArgs:[id]);

  Future<void> saveInvestment(InvestmentPosition x) async => (await database).insert('investments', x.toMap(), conflictAlgorithm:ConflictAlgorithm.replace);
  Future<List<InvestmentPosition>> investments() async => (await database).query('investments', orderBy:'name').then((r) => r.map(InvestmentPosition.fromMap).toList());
  Future<void> deleteInvestment(String id) async => (await database).delete('investments', where:'id=?', whereArgs:[id]);

  Future<void> setting(String key, String value) async => (await database).insert('app_settings', {'key':key,'value':value}, conflictAlgorithm:ConflictAlgorithm.replace);
  Future<String?> getSetting(String key) async {
    final r = await (await database).query('app_settings', where:'key=?', whereArgs:[key], limit:1);
    return r.isEmpty ? null : r.first['value'] as String;
  }
}
