import 'package:injectable/injectable.dart';
import 'package:kakikaki/features/my/data/source/device_info_data_source.dart';
import 'package:kakikaki/features/my/data/source/inquiry_remote_data_source.dart';
import 'package:kakikaki/features/my/domain/repository/inquiry_repository.dart';

@Injectable(as: InquiryRepository)
class InquiryRepositoryImpl implements InquiryRepository {
  InquiryRepositoryImpl(this._remoteDataSource, this._deviceInfoDataSource);

  final InquiryRemoteDataSource _remoteDataSource;
  final DeviceInfoDataSource _deviceInfoDataSource;

  @override
  Future<void> submitInquiry({
    required String userId,
    required String category,
    required String title,
    required String content,
  }) async {
    final deviceInfo = await _deviceInfoDataSource.collectDeviceInfo();
    await _remoteDataSource.submitInquiry(
      userId: userId,
      category: category,
      title: title,
      content: content,
      deviceInfo: deviceInfo,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getInquiries({
    required String userId,
  }) =>
      _remoteDataSource.getInquiries(userId: userId);
}
