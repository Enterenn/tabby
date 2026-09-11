"""
Calcul du solde d'un groupe : qui doit combien à qui.

Algorithme :
  1. Pour chaque dépense, le payeur a avancé `amount` pour tout le groupe.
  2. Chaque membre doit sa part (expense_split.amount) au payeur.
  3. On agrège les dettes nettes entre chaque paire (A→B) et (B→A),
     puis on les simplifie : seule la différence nette subsiste.
  4. Le solde d'un utilisateur donné = somme de ce que les autres lui doivent
     moins ce qu'il doit aux autres.

Les montants en entrée sont des Decimal ou float ; on travaille en float
arrondi à 2 décimales en sortie.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal


@dataclass
class ExpenseRecord:
    paid_by: str          # user_id du payeur
    splits: list[tuple[str, Decimal]]  # [(user_id, amount), ...]


@dataclass
class DebtEntry:
    debtor: str   # user_id qui doit
    creditor: str # user_id à qui on doit
    amount: float


def compute_balances(expenses: list[ExpenseRecord]) -> list[DebtEntry]:
    """
    Retourne la liste minimale de transferts pour solder le groupe.

    On construit d'abord un graphe de dettes brutes (paires ordonnées),
    puis on simplifie chaque paire en ne gardant que la dette nette.
    """
    raw: dict[tuple[str, str], Decimal] = {}

    for exp in expenses:
        for user_id, share in exp.splits:
            if user_id == exp.paid_by:
                continue  # le payeur ne se doit rien à lui-même
            key = (user_id, exp.paid_by)  # debtor → creditor
            raw[key] = raw.get(key, Decimal("0")) + share

    # Simplification des dettes inverses
    settled: dict[tuple[str, str], Decimal] = {}
    processed: set[tuple[str, str]] = set()

    for (debtor, creditor), amount in raw.items():
        if (debtor, creditor) in processed:
            continue
        reverse = raw.get((creditor, debtor), Decimal("0"))
        net = amount - reverse
        if net > 0:
            settled[(debtor, creditor)] = net
        elif net < 0:
            settled[(creditor, debtor)] = -net
        processed.add((debtor, creditor))
        processed.add((creditor, debtor))

    return [
        DebtEntry(debtor=d, creditor=c, amount=round(float(a), 2))
        for (d, c), a in settled.items()
        if a > 0
    ]


def user_balance(user_id: str, debts: list[DebtEntry]) -> float:
    """
    Solde net de l'utilisateur dans le groupe.
    Positif = on lui doit de l'argent. Négatif = il doit de l'argent.
    """
    total = sum(d.amount for d in debts if d.creditor == user_id)
    total -= sum(d.amount for d in debts if d.debtor == user_id)
    return round(total, 2)
