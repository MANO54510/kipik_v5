// lib/mock/mock_booking.dart

import '../models/flash/flash_booking.dart';
import '../models/flash/flash_booking_status.dart';

final FlashBooking mockBooking = FlashBooking(
  id: 'booking_mock_1',
  flashId: 'flash_mock_1',
  clientId: 'client_mock_1',
  tattooArtistId: 'tatoueur_mock_1',
  requestedDate: DateTime.now().add(Duration(days: 2)),
  timeSlot: '14:00-15:00',
  status: FlashBookingStatus.pending,
  totalPrice: 150.0,
  depositAmount: 50.0,
  clientNotes: 'Je souhaite un motif floral.',
  clientPhone: '+33612345678',
  artistNotes: 'RDV fixé, prévoir stencil.',
  rejectionReason: null,
  paymentIntentId: null,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
