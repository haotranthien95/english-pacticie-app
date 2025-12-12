import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';

/// Response model for speech scoring
class SpeechScoreResponse {
  final double pronunciationScore;
  final String transcribedText;
  final Map<String, double> wordScores;
  final Map<String, dynamic>? detailedMetrics;

  SpeechScoreResponse({
    required this.pronunciationScore,
    required this.transcribedText,
    required this.wordScores,
    this.detailedMetrics,
  });

  factory SpeechScoreResponse.fromJson(Map<String, dynamic> json) {
    return SpeechScoreResponse(
      pronunciationScore: (json['pronunciation_score'] as num).toDouble(),
      transcribedText: json['transcribed_text'] as String,
      wordScores: Map<String, double>.from(
        (json['word_scores'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      detailedMetrics: json['detailed_metrics'] as Map<String, dynamic>?,
    );
  }
}

/// Remote data source for speech-to-text and pronunciation scoring
abstract class SpeechRemoteDataSource {
  /// Score pronunciation by sending audio bytes to backend
  Future<SpeechScoreResponse> scorePronunciation({
    required Uint8List audioBytes,
    required String referenceText,
    required String language,
  });
}

class SpeechRemoteDataSourceImpl implements SpeechRemoteDataSource {
  final Dio dio;

  SpeechRemoteDataSourceImpl({required this.dio});

  @override
  Future<SpeechScoreResponse> scorePronunciation({
    required Uint8List audioBytes,
    required String referenceText,
    required String language,
  }) async {
    try {
      // Create multipart file from audio bytes
      final multipartFile = MultipartFile.fromBytes(
        audioBytes,
        filename: 'audio.m4a',
        contentType: MediaType('audio', 'm4a'),
      );

      // Create form data
      final formData = FormData.fromMap({
        'audio': multipartFile,
        'reference_text': referenceText,
        'language': language,
      });

      // Send POST request
      final response = await dio.post(
        ApiEndpoints.scoreSpeech,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return SpeechScoreResponse.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      } else {
        throw ServerException(
          message: 'Failed to score pronunciation: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error scoring pronunciation: $e',
      );
    }
  }

  /// Handle Dio errors and convert to appropriate exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] as String?;

        if (statusCode == 401) {
          return UnauthorizedException(
            message: message ?? 'Unauthorized access',
          );
        } else if (statusCode == 404) {
          return ServerException(message: message ?? 'Resource not found');
        } else if (statusCode == 422) {
          return ValidationException(
            message: message ?? 'Invalid audio or reference text',
          );
        } else if (statusCode == 413) {
          return ValidationException(
            message: 'Audio file too large. Maximum size is 10MB.',
          );
        } else {
          return ServerException(
            message: message ?? 'Server error: $statusCode',
          );
        }

      case DioExceptionType.cancel:
        return NetworkException(message: 'Request cancelled');

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return NetworkException(message: 'No internet connection');
        }
        return NetworkException(message: 'Network error: ${error.message}');

      default:
        return ServerException(message: 'Unexpected error: ${error.message}');
    }
  }
}
