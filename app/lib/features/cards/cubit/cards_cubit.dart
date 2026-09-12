import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/models/loyalty_card.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class CardsState extends Equatable {
  const CardsState();
  @override
  List<Object?> get props => [];
}

class CardsInitial extends CardsState {
  const CardsInitial();
}

class CardsLoading extends CardsState {
  const CardsLoading();
}

class CardsLoaded extends CardsState {
  const CardsLoaded(this.cards);
  final List<LoyaltyCard> cards;
  @override
  List<Object?> get props => [cards];
}

class CardsError extends CardsState {
  const CardsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

class CardsCubit extends Cubit<CardsState> {
  CardsCubit() : super(const CardsInitial());

  Future<void> load() async {
    emit(const CardsLoading());
    try {
      final resp = await apiClient.dio.get('/loyalty-cards');
      final cards = (resp.data as List)
          .map((c) => LoyaltyCard.fromJson(c as Map<String, dynamic>))
          .toList();
      emit(CardsLoaded(cards));
    } catch (e) {
      emit(CardsError(e.toString()));
    }
  }

  Future<bool> addCard({
    required String brandName,
    required String codeType,
    required String codeValue,
    String? color,
    String? brandId,
  }) async {
    try {
      await apiClient.dio.post(
        '/loyalty-cards',
        data: {
          'brand_name': brandName,
          'code_type': codeType,
          'code_value': codeValue,
          'color': ?color,
          'brand_id': ?brandId,
        },
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    try {
      await apiClient.dio.delete('/loyalty-cards/$id');
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reorder(List<LoyaltyCard> newOrder) async {
    // Mise à jour optimiste locale
    emit(CardsLoaded(newOrder));
    try {
      await apiClient.dio.put(
        '/loyalty-cards/reorder',
        data: newOrder
            .asMap()
            .entries
            .map((e) => {'id': e.value.id, 'sort_order': e.key})
            .toList(),
      );
    } catch (_) {
      await load(); // rollback si erreur
    }
  }
}
