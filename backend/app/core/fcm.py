"""Firebase Cloud Messaging — envoi de notifications push."""

import logging
import os
from typing import Sequence

import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)

_initialized = False


def _init() -> bool:
    global _initialized
    if _initialized:
        return True

    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "/run/secrets/firebase.json")
    if not os.path.exists(cred_path):
        logger.warning(
            "[FCM] Fichier de credentials introuvable (%s) — notifications désactivées",
            cred_path,
        )
        return False

    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        _initialized = True
        logger.info("[FCM] Firebase initialisé")
        return True
    except Exception as exc:
        logger.error("[FCM] Erreur d'initialisation : %s", exc)
        return False


def send_expense_notification(
    *,
    tokens: Sequence[str],
    group_name: str,
    expense_name: str,
    amount: float,
    group_id: str,
    payer_name: str,
) -> None:
    """Envoie une notification 'nouvelle dépense' à une liste de tokens FCM."""
    if not tokens:
        return
    if not _init():
        return

    title = group_name
    body = f"{payer_name} a ajouté · {expense_name} · {amount:.2f} €"

    message = messaging.MulticastMessage(
        tokens=list(tokens),
        notification=messaging.Notification(title=title, body=body),
        data={"group_id": group_id},
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                sound="default",
                click_action="FLUTTER_NOTIFICATION_CLICK",
            ),
        ),
    )
    _send_multicast(message)


def send_settle_request_notification(
    *,
    tokens: Sequence[str],
    group_name: str,
    amount: float,
    group_id: str,
    payer_name: str,
) -> None:
    """Demande de confirmation de remboursement au créancier."""
    if not tokens or not _init():
        return
    _send_multicast(
        messaging.MulticastMessage(
            tokens=list(tokens),
            notification=messaging.Notification(
                title=group_name,
                body=(
                    f"{payer_name} t'a envoyé un remboursement de "
                    f"{amount:.2f} € — confirme-le"
                ),
            ),
            data={"group_id": group_id},
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    sound="default",
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            ),
        )
    )


def send_settle_confirmed_notification(
    *,
    tokens: Sequence[str],
    group_name: str,
    amount: float,
    group_id: str,
    confirmer_name: str,
) -> None:
    """Le payeur apprend que son remboursement a été confirmé."""
    if not tokens or not _init():
        return
    _send_multicast(
        messaging.MulticastMessage(
            tokens=list(tokens),
            notification=messaging.Notification(
                title=group_name,
                body=(
                    f"{confirmer_name} a confirmé ton remboursement de "
                    f"{amount:.2f} €"
                ),
            ),
            data={"group_id": group_id},
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    sound="default",
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            ),
        )
    )


def _send_multicast(message: messaging.MulticastMessage) -> None:
    try:
        response = messaging.send_each_for_multicast(message)
        logger.info(
            "[FCM] %d succès / %d échecs",
            response.success_count,
            response.failure_count,
        )
    except Exception as exc:
        logger.error("[FCM] send_each_for_multicast error: %s", exc)
