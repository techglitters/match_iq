import '../../features/themes/domain/app_progress_data.dart';
import 'progress_store.dart';

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([AppProgressData? initialData])
    : _data = initialData ?? const AppProgressData.initial();

  AppProgressData _data;

  @override
  Future<AppProgressData> load() async {
    return _data;
  }

  @override
  Future<void> save(AppProgressData data) async {
    _data = data;
  }
}
