/*
 * Copyright (C) 2022-2024 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../app/logging.dart';
import '../app/state.dart';
import 'state.dart';
import 'views/nfc/models.dart';
import 'views/nfc/nfc_activity_overlay.dart';
import 'views/nfc/nfc_content_widget.dart';
import 'views/nfc/nfc_failure_icon.dart';
import 'views/nfc/nfc_progress_bar.dart';
import 'views/nfc/nfc_success_icon.dart';

final _log = Logger('android.tap_request_dialog');
const _channel = MethodChannel('com.yubico.authenticator.channel.dialog');

final androidDialogProvider =
    NotifierProvider<_DialogProvider, int>(_DialogProvider.new);

class _DialogProvider extends Notifier<int> {
  Timer? processingViewTimeout;
  bool explicitAction = false;

  late final l10n = ref.read(l10nProvider);

  @override
  int build() {
    final viewNotifier = ref.read(nfcViewNotifier.notifier);

    ref.listen(androidNfcActivityProvider, (previous, current) {
      final notifier = ref.read(nfcEventCommandNotifier.notifier);

      if (!explicitAction) {
        // setup properties for ad-hoc action
        viewNotifier.setDialogProperties(showCloseButton: false);
      }

      switch (current) {
        case NfcActivity.processingStarted:
          final timeout = explicitAction ? 300 : 500;
          processingViewTimeout?.cancel();
          processingViewTimeout = Timer(Duration(milliseconds: timeout), () {
            notifier.sendCommand(showScanning());
          });
          break;
        case NfcActivity.processingFinished:
          processingViewTimeout?.cancel();
          notifier.sendCommand(showDone());
          notifier.sendCommand(hideNfcView(const Duration(milliseconds: 400)));

          explicitAction = false; // next action might not be explicit
          break;
        case NfcActivity.processingInterrupted:
          processingViewTimeout?.cancel();
          notifier.sendCommand(showFailed());
          break;
        case NfcActivity.notActive:
          _log.debug('Received not handled notActive');
          break;
        case NfcActivity.ready:
          _log.debug('Received not handled ready');
      }
    });

    _channel.setMethodCallHandler((call) async {
      final notifier = ref.read(nfcEventCommandNotifier.notifier);
      switch (call.method) {
        case 'show':
          explicitAction = true;
          notifier.sendCommand(showTapYourYubiKey());
          break;

        case 'close':
          closeDialog();
          break;

        default:
          throw PlatformException(
            code: 'NotImplemented',
            message: 'Method ${call.method} is not implemented',
          );
      }
    });
    return 0;
  }

  NfcEventCommand showTapYourYubiKey() {
    ref
        .read(nfcViewNotifier.notifier)
        .setDialogProperties(showCloseButton: true);
    return setNfcView(NfcContentWidget(
      title: l10n.s_nfc_ready_to_scan,
      subtitle: l10n.s_nfc_tap_your_yubikey,
      icon: const NfcIconProgressBar(false),
    ));
  }

  NfcEventCommand showScanning() {
    ref
        .read(nfcViewNotifier.notifier)
        .setDialogProperties(showCloseButton: false);
    return setNfcView(NfcContentWidget(
      title: l10n.s_nfc_ready_to_scan,
      subtitle: l10n.s_nfc_scanning,
      icon: const NfcIconProgressBar(true),
    ));
  }

  NfcEventCommand showDone() {
    ref
        .read(nfcViewNotifier.notifier)
        .setDialogProperties(showCloseButton: true);
    return setNfcView(
        NfcContentWidget(
          title: l10n.s_nfc_ready_to_scan,
          subtitle: l10n.s_done,
          icon: const NfcIconSuccess(),
        ),
        showIfHidden: false);
  }

  NfcEventCommand showFailed() {
    ref
        .read(nfcViewNotifier.notifier)
        .setDialogProperties(showCloseButton: true);
    return setNfcView(
        NfcContentWidget(
          title: l10n.s_nfc_ready_to_scan,
          subtitle: l10n.l_nfc_failed_to_scan,
          icon: const NfcIconFailure(),
        ),
        showIfHidden: false);
  }

  void closeDialog() {
    ref.read(nfcEventCommandNotifier.notifier).sendCommand(hideNfcView());
  }

  void cancelDialog() async {
    explicitAction = false;
    await _channel.invokeMethod('cancel');
  }

  Future<void> waitForDialogClosed() async {
    final completer = Completer();

    Timer.periodic(
      const Duration(milliseconds: 200),
      (timer) {
        if (!ref.read(nfcViewNotifier.select((s) => s.isShowing))) {
          timer.cancel();
          completer.complete();
        }
      },
    );

    await completer.future;
  }
}
