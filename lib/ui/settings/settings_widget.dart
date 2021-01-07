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

import 'package:flutter/material.dart';
import 'package:receipt_manager/generated/l10n.dart';
import 'package:receipt_manager/ui/settings/api_settings.dart';
import 'package:receipt_manager/ui/settings/server_settings.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language_setting.dart';

class SettingsWidget extends StatefulWidget {
  final SharedPreferences sharedPreferences;

  SettingsWidget(this.sharedPreferences);

  @override
  _SettingsWidgetState createState() => _SettingsWidgetState(sharedPreferences);
}

class _SettingsWidgetState extends State<SettingsWidget> {
  // fallback settings
  bool enableHighContrast = false;
  bool enableDebug = false;
  bool legacyParser = true;


  final SharedPreferences sharedPreferences;

  _SettingsWidgetState(this.sharedPreferences);

  @override
  Widget build(BuildContext context) {
     enableDebug = sharedPreferences.getBool("enable_debug_output") == null ? enableDebug : sharedPreferences.getBool("enable_debug_output") ;
     legacyParser = sharedPreferences.getBool("legacyParser") == null ? legacyParser : sharedPreferences.getBool("legacyParser") ;
     enableHighContrast = sharedPreferences.getBool("high_contrast") == null ? enableDebug : sharedPreferences.getBool("high_contrast") ;

     return Column(children: [
      SettingsList(
        shrinkWrap: true,
        sections: [
          SettingsSection(
            title: S.of(context).settingsGeneralCategory,
            tiles: [
              SettingsTile(
                title: S.of(context).settingsLanguageTitle,
                subtitle: S.of(context).currentLanguage,
                leading: Icon(Icons.language),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) => LanguageSetting(sharedPreferences)));
                },
              ),
              SettingsTile(
                title: S.of(context).settingsServerTitle,
                leading: Icon(Icons.wifi),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          ServerSettings(sharedPreferences)));
                },
              ),
              SettingsTile(
                title: S.of(context).apitoken,
                leading: Icon(Icons.vpn_key),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          ApiSettings(sharedPreferences)));
                },
              ),
            ],
          ),
          SettingsSection(
            title: S.of(context).cameraSettings,
            tiles: [
              SettingsTile.switchTile(
                title: S.of(context).highContrast,
                leading: Icon(Icons.wb_incandescent_outlined),
                switchValue: enableHighContrast,
                onToggle: (bool value) {
                  setState(() {
                    enableHighContrast = value;
                    sharedPreferences.setBool("high_contrast", value);
                  });
                },
              ),
              SettingsTile.switchTile(
                title: S.of(context).neuronalNetworkParser,
                leading: Icon(Icons.camera_enhance_outlined),
                switchValue: !legacyParser,
                onToggle: (bool value) {
                  setState(() {
                    legacyParser = !value;
                    sharedPreferences.setBool("legacyParser", !value);
                  });
                },
              ),
              SettingsTile.switchTile(
                title: S.of(context).fuzzyParser,
                leading: Icon(Icons.camera_enhance_rounded),
                switchValue: legacyParser,
                onToggle: (bool value) {
                  setState(() {
                    legacyParser = value;
                    sharedPreferences.setBool("legacyParser", value);
                  });
                },
              ),
            ],
          ),
          SettingsSection(
            title: S.of(context).settingsDevelopmentTitle,
            tiles: [
              SettingsTile.switchTile(
                title: S.of(context).enableDebugOutput,
                leading: Icon(Icons.bug_report),
                switchValue: enableDebug,
                onToggle: (bool value) {
                  setState(() {
                    enableDebug = value;
                    sharedPreferences.setBool("enable_debug_output", value);
                  });
                },
              ),
            ],
          )
        ],
      )
    ]);
  }
}
