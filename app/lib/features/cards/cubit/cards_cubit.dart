import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
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
      final cards = await cardsRepository.list();
      if (!isClosed) emit(CardsLoaded(cards));
    } catch (e) {
      if (!isClosed) emit(CardsError(ApiFailure.from(e).message));
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
      await cardsRepository.add(
        brandName: brandName,
        codeType: codeType,
        codeValue: codeValue,
        color: color,
        brandId: brandId,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    try {
      await cardsRepository.delete(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reorder(List<LoyaltyCard> newOrder) async {
    // Mise à jour optimiste locale
    if (!isClosed) emit(CardsLoaded(newOrder));
    try {
      await cardsRepository.reorder(newOrder);
    } catch (_) {
      await load();
    }
  }
}
