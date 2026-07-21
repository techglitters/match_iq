import '../../features/themes/domain/app_progress_data.dart';

abstract interface class ProgressStore {
  Future<AppProgressData> load();

  Future<void> save(AppProgressData data);
}
