"""Tests unitaires — calcul du solde d'un groupe (logique critique)."""

from decimal import Decimal

import pytest

from app.core.balance import DebtEntry, ExpenseRecord, compute_balances, user_balance

A = "user-a"
B = "user-b"
C = "user-c"


# ---------------------------------------------------------------------------
# Cas simples — deux personnes
# ---------------------------------------------------------------------------

def test_equal_split_two_people():
    """A paie 100€, partagé en deux → B doit 50€ à A."""
    expenses = [
        ExpenseRecord(paid_by=A, splits=[(A, Decimal("50")), (B, Decimal("50"))])
    ]
    debts = compute_balances(expenses)
    assert len(debts) == 1
    assert debts[0].debtor == B
    assert debts[0].creditor == A
    assert debts[0].amount == 50.0


def test_mutual_expenses_simplify():
    """A paie 60€ pour B, B paie 40€ pour A → dette nette de 20€."""
    expenses = [
        ExpenseRecord(paid_by=A, splits=[(A, Decimal("0")), (B, Decimal("60"))]),
        ExpenseRecord(paid_by=B, splits=[(B, Decimal("0")), (A, Decimal("40"))]),
    ]
    debts = compute_balances(expenses)
    assert len(debts) == 1
    assert debts[0].debtor == B
    assert debts[0].creditor == A
    assert debts[0].amount == 20.0


def test_already_settled():
    """A paie 50€ pour B, B paie 50€ pour A → solde nul."""
    expenses = [
        ExpenseRecord(paid_by=A, splits=[(B, Decimal("50"))]),
        ExpenseRecord(paid_by=B, splits=[(A, Decimal("50"))]),
    ]
    debts = compute_balances(expenses)
    assert debts == []


# ---------------------------------------------------------------------------
# Cas à trois personnes
# ---------------------------------------------------------------------------

def test_three_people_equal_split():
    """A paie 90€ partagé en 3 → B et C doivent chacun 30€ à A."""
    expenses = [
        ExpenseRecord(
            paid_by=A,
            splits=[(A, Decimal("30")), (B, Decimal("30")), (C, Decimal("30"))],
        )
    ]
    debts = compute_balances(expenses)
    assert len(debts) == 2
    creditors = {d.creditor for d in debts}
    debtors = {d.debtor for d in debts}
    assert creditors == {A}
    assert debtors == {B, C}
    for d in debts:
        assert d.amount == 30.0


def test_three_people_multiple_expenses():
    """
    A paie 60€ (30/30 avec B), B paie 90€ (30/30/30 avec A et C).
    Dettes brutes : B→A 30, A→B 30, C→B 30.
    Nette : A↔B s'annulent ; C doit 30 à B.
    """
    expenses = [
        ExpenseRecord(paid_by=A, splits=[(A, Decimal("30")), (B, Decimal("30"))]),
        ExpenseRecord(
            paid_by=B,
            splits=[(A, Decimal("30")), (B, Decimal("30")), (C, Decimal("30"))],
        ),
    ]
    debts = compute_balances(expenses)
    assert len(debts) == 1
    assert debts[0].debtor == C
    assert debts[0].creditor == B
    assert debts[0].amount == 30.0


# ---------------------------------------------------------------------------
# Répartition personnalisée
# ---------------------------------------------------------------------------

def test_custom_split():
    """A paie 100€ : A→20, B→50, C→30."""
    expenses = [
        ExpenseRecord(
            paid_by=A,
            splits=[(A, Decimal("20")), (B, Decimal("50")), (C, Decimal("30"))],
        )
    ]
    debts = compute_balances(expenses)
    amounts = {d.debtor: d.amount for d in debts}
    assert amounts[B] == 50.0
    assert amounts[C] == 30.0
    assert all(d.creditor == A for d in debts)


# ---------------------------------------------------------------------------
# user_balance
# ---------------------------------------------------------------------------

def test_user_balance_positive():
    """On doit de l'argent à A → solde positif."""
    debts = [DebtEntry(debtor=B, creditor=A, amount=50.0)]
    assert user_balance(A, debts) == 50.0


def test_user_balance_negative():
    """A doit de l'argent → solde négatif."""
    debts = [DebtEntry(debtor=A, creditor=B, amount=30.0)]
    assert user_balance(A, debts) == -30.0


def test_user_balance_neutral():
    """A doit 20 à B mais C lui doit 20 → solde nul."""
    debts = [
        DebtEntry(debtor=A, creditor=B, amount=20.0),
        DebtEntry(debtor=C, creditor=A, amount=20.0),
    ]
    assert user_balance(A, debts) == 0.0
