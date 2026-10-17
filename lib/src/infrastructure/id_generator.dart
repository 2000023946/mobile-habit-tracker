
import 'package:uuid/uuid.dart';

import '../ports/id_generator.dart';

class UuidIdGenerator implements IdGenerator {
  static const Uuid _uuid = Uuid();

  const UuidIdGenerator();

  @override
  String newId() {
    return _uuid.v4();
  }
}
