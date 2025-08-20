import 'package:equatable/equatable.dart';

class S3Config extends Equatable {
  final String endpoint;
  final String region;
  final String accessKeyId;
  final String secretAccessKey;
  final String bucketName;
  final bool useSSL;
  final int? port;

  const S3Config({
    required this.endpoint,
    required this.region,
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.bucketName,
    this.useSSL = true,
    this.port,
  });

  /// Create S3Config for AWS S3
  factory S3Config.aws({
    required String region,
    required String accessKeyId,
    required String secretAccessKey,
    required String bucketName,
  }) {
    return S3Config(
      endpoint: 's3.$region.amazonaws.com',
      region: region,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      bucketName: bucketName,
      useSSL: true,
    );
  }

  /// Create S3Config for MinIO
  factory S3Config.minio({
    required String endpoint,
    required String accessKeyId,
    required String secretAccessKey,
    required String bucketName,
    bool useSSL = false,
    int? port,
  }) {
    return S3Config(
      endpoint: endpoint,
      region: 'us-east-1', // Default region for MinIO
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      bucketName: bucketName,
      useSSL: useSSL,
      port: port,
    );
  }

  /// Get full endpoint URL
  String get fullEndpoint {
    final protocol = useSSL ? 'https' : 'http';
    final portSuffix = port != null ? ':$port' : '';
    return '$protocol://$endpoint$portSuffix';
  }

  /// Check if configuration is valid
  bool get isValid {
    return endpoint.isNotEmpty &&
           region.isNotEmpty &&
           accessKeyId.isNotEmpty &&
           secretAccessKey.isNotEmpty &&
           bucketName.isNotEmpty;
  }

  /// Create a copy with updated fields
  S3Config copyWith({
    String? endpoint,
    String? region,
    String? accessKeyId,
    String? secretAccessKey,
    String? bucketName,
    bool? useSSL,
    int? port,
  }) {
    return S3Config(
      endpoint: endpoint ?? this.endpoint,
      region: region ?? this.region,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretAccessKey: secretAccessKey ?? this.secretAccessKey,
      bucketName: bucketName ?? this.bucketName,
      useSSL: useSSL ?? this.useSSL,
      port: port ?? this.port,
    );
  }

  @override
  List<Object?> get props => [
        endpoint,
        region,
        accessKeyId,
        secretAccessKey,
        bucketName,
        useSSL,
        port,
      ];

  @override
  String toString() {
    return 'S3Config(endpoint: $endpoint, region: $region, bucket: $bucketName, useSSL: $useSSL)';
  }
}