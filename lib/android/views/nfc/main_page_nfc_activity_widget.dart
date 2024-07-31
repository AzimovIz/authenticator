/*
 * Copyright (C) 2023 Yubico.
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

import 'package:flutter/material.dart';

import '../../../app/views/horizontal_shake.dart';
import '../../state.dart';
import 'nfc_activity_widget.dart';

class MainPageNfcActivityWidget extends StatelessWidget {
  final Widget widget;

  const MainPageNfcActivityWidget(this.widget, {super.key});

  @override
  Widget build(BuildContext context) {
    return NfcActivityWidget(
      width: 128.0,
      height: 128.0,
      iconView: (nfcActivityState) {
        return switch (nfcActivityState) {
          NfcActivity.ready => HorizontalShake(
              shakeCount: 2,
              shakeDuration: const Duration(milliseconds: 50),
              delayBetweenShakesDuration: const Duration(seconds: 6),
              startupDelay: const Duration(seconds: 3),
              child: widget,
            ),
          _ => widget
        };
      },
    );
  }
}
