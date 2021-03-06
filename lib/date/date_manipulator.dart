/*
 *  Copyright (c) 2020 - William Todt
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:receipt_manager/generated/l10n.dart';

class DateManipulator {
  static String humanDate(BuildContext context, DateTime dateTime) {
    if (dateTime == null) return " ";

    return DateFormat(S.of(context).receiptDateFormat).format(dateTime);
  }
}
