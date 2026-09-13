import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_failure.dart';
import '../../../data/repositories.dart';
import '../../../shared/models/loyalty_card.dart';
import '../../../shared/models/loyalty_card_usage.dart';

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
  const CardsLoaded(this.cards, {this.frequent = const []});
  final List<LoyaltyCard> cards;
  final List<LoyaltyCard> frequent;
  @override
  List<Object?> get props => [cards, frequent];
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
      if (!isClosed) emit(await _loaded(cards, prune: true));
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
    } catch (e) {
      if (!isClosed) emit(CardsError(ApiFailure.from(e).message));
      return false;
    }
  }

  Future<bool> updateCard({
    required String id,
    required String brandName,
    required String codeType,
    required String codeValue,
    String? color,
    String? brandId,
  }) async {
    try {
      await cardsRepository.update(
        id: id,
        brandName: brandName,
        codeType: codeType,
        codeValue: codeValue,
        color: color,
        brandId: brandId,
      );
      await load();
      return true;
    } catch (e) {
      if (!isClosed) emit(CardsError(ApiFailure.from(e).message));
      return false;
    }
  }

  Future<bool> deleteCard(String id) async {
    try {
      await cardsRepository.delete(id);
      await LoyaltyCardUsageStore.forget(id);
      await load();
      return true;
    } catch (e) {
      if (!isClosed) emit(CardsError(ApiFailure.from(e).message));
      return false;
    }
  }

  Future<void> reorder(List<LoyaltyCard> newOrder) async {
    // Mise à jour optimiste locale
    if (!isClosed) emit(await _loaded(newOrder));
    try {
      await cardsRepository.reorder(newOrder);
    } catch (e) {
      if (!isClosed) emit(CardsError(ApiFailure.from(e).message));
      await load();
    }
  }

  Future<void> recordOpen(String cardId) async {
    await LoyaltyCardUsageStore.recordOpen(cardId);
    final current = state;
    if (current is! CardsLoaded || isClosed) return;
    emit(await _loaded(current.cards));
  }

  Future<CardsLoaded> _loaded(
    List<LoyaltyCard> cards, {
    bool prune = false,
  }) async {
    await LoyaltyCardUsageStore.load();
    if (prune) {
      await LoyaltyCardUsageStore.forgetMissing(cards.map((card) => card.id));
    }
    return CardsLoaded(cards, frequent: LoyaltyCardUsageStore.frequentOf(cards));
  }
}
