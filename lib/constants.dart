import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get extractionEndpoint => dotenv.env['EXTRACTION_ENDPOINT'] ?? '/extract-ledger/';
  static String get fullExtractionUrl => '$apiBaseUrl$extractionEndpoint';
  static String get clientsEndpoint => '/api/clients/';
  static String get fullClientsUrl => '$apiBaseUrl$clientsEndpoint';
  static String get transactionsEndpoint => '/api/transactions/';
  static String get fullTransactionsUrl => '$apiBaseUrl$transactionsEndpoint';
}
