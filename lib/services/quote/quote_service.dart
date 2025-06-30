import '../../models/quote_request.dart';

abstract class QuoteService {
  Future<List<QuoteRequest>> fetchRequestsForPro();
  Future<List<QuoteRequest>> fetchRequestsForParticulier();
  Future<QuoteRequest> fetchRequestDetail(String id);
  Future<void> acceptRequest(String id);
  Future<void> refuseRequest(String id);
  Future<void> sendQuote(String id, double price, String details);
  Future<void> clientAccept(String id);
  Future<void> clientRefuse(String id);
}
