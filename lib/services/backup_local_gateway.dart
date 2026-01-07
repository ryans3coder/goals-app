import '../models/backup_snapshot.dart';
import 'backup_controller.dart';
import 'data_provider.dart';

class DataProviderBackupGateway implements BackupLocalGateway {
  DataProviderBackupGateway({required DataProvider dataProvider})
      : _dataProvider = dataProvider;

  final DataProvider _dataProvider;

  @override
  Future<BackupSnapshot> buildSnapshot() => _dataProvider.buildBackupSnapshot();

  @override
  Future<void> restoreSnapshot(BackupSnapshot snapshot) {
    return _dataProvider.restoreFromSnapshot(snapshot);
  }
}
