import 'package:sqlite3/sqlite3.dart';

class DatabaseSchema {
  DatabaseSchema._();

  static const int version = 1;

  /// Creates all tables and indexes required by the application.
  ///
  /// Safe to call more than once because the tables and indexes use
  /// IF NOT EXISTS.
  static void create(Database database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL COLLATE NOCASE UNIQUE,
        created_at INTEGER NOT NULL
      );
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        habit_type TEXT NOT NULL,

        scheduled_days TEXT,
        weekly_target_minutes INTEGER,

        target REAL,
        target_type TEXT,

        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,

        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,

        CHECK (
          category IN (
            'physicalActivity',
            'studyAndLearning',
            'mindAndFocus',
            'mindfulnessAndWellbeing'
          )
        ),

        CHECK (
          habit_type IN ('execution', 'avoidance')
        ),

        CHECK (
          (
            habit_type = 'execution'
            AND scheduled_days IS NOT NULL
            AND weekly_target_minutes IS NOT NULL
            AND weekly_target_minutes > 0
            AND target IS NULL
            AND target_type IS NULL
          )
          OR
          (
            habit_type = 'avoidance'
            AND target IS NOT NULL
            AND target >= 0
            AND target_type IN ('timeLimit', 'quantityLimit')
            AND scheduled_days IS NULL
            AND weekly_target_minutes IS NULL
          )
        )
      );
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_habits_user
      ON habits(user_id);
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_habits_user_category
      ON habits(user_id, category);
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS category_progress (
        user_id TEXT NOT NULL,
        category TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        current_exp INTEGER NOT NULL DEFAULT 0,
        lifetime_exp INTEGER NOT NULL DEFAULT 0,

        PRIMARY KEY (user_id, category),

        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,

        CHECK (level >= 1),
        CHECK (current_exp >= 0),
        CHECK (lifetime_exp >= 0),

        CHECK (
          category IN (
            'physicalActivity',
            'studyAndLearning',
            'mindAndFocus',
            'mindfulnessAndWellbeing'
          )
        )
      );
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS habit_check_ins (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        actual_value REAL NOT NULL,
        occurred_at INTEGER NOT NULL,
        occurred_date TEXT NOT NULL,

        FOREIGN KEY (habit_id)
          REFERENCES habits(id)
          ON DELETE CASCADE,

        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,

        CHECK (actual_value >= 0),

        UNIQUE (habit_id, occurred_date)
      );
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_check_ins_user_date
      ON habit_check_ins(user_id, occurred_at);
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_check_ins_habit_date
      ON habit_check_ins(habit_id, occurred_at);
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS streaks (
        habit_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        current_days INTEGER NOT NULL DEFAULT 0,
        longest_days INTEGER NOT NULL DEFAULT 0,
        last_successful_date TEXT,

        FOREIGN KEY (habit_id)
          REFERENCES habits(id)
          ON DELETE CASCADE,

        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,

        CHECK (current_days >= 0),
        CHECK (longest_days >= 0),
        CHECK (longest_days >= current_days)
      );
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_streaks_user
      ON streaks(user_id);
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS experience_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        habit_id TEXT NOT NULL,
        category TEXT NOT NULL,
        category_progress_key TEXT NOT NULL,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at INTEGER NOT NULL,

        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,

        CHECK (
          category IN (
            'physicalActivity',
            'studyAndLearning',
            'mindAndFocus',
            'mindfulnessAndWellbeing'
          )
        ),

        CHECK (
          type IN (
            'executionReward',
            'avoidanceReward',
            'avoidanceViolationPenalty',
            'missedCommitmentPenalty',
            'adjustment'
          )
        ),

        CHECK (
          (type IN ('executionReward', 'avoidanceReward')
            AND amount >= 0)
          OR
          (type IN (
            'avoidanceViolationPenalty',
            'missedCommitmentPenalty'
          ) AND amount <= 0)
          OR type = 'adjustment'
        )
      );
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_user_date
      ON experience_transactions(user_id, created_at);
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_habit
      ON experience_transactions(habit_id, created_at);
    ''');

    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_transactions_category
      ON experience_transactions(user_id, category);
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS schema_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    database.execute(
      '''
      INSERT INTO schema_metadata (key, value)
      VALUES ('schema_version', ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value;
      ''',
      [version.toString()],
    );
  }
}