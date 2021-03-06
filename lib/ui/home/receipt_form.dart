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

import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:receipt_manager/bloc/moor/bloc.dart';
import 'package:receipt_manager/database/receipt_database.dart';
import 'package:receipt_manager/date/date_manipulator.dart';
import 'package:receipt_manager/factory/banner_factory.dart';
import 'package:receipt_manager/factory/categories_factory.dart';
import 'package:receipt_manager/factory/padding_factory.dart';
import 'package:receipt_manager/factory/text_form_history.dart';
import 'package:receipt_manager/generated/l10n.dart';
import 'package:receipt_manager/generator/receipt_generator.dart';
import 'package:receipt_manager/model/receipt_category.dart';
import 'package:receipt_manager/network/network_client.dart';
import 'package:receipt_manager/theme/theme_manager.dart';
import 'package:receipt_manager/util/dimensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../parser/camera_picker.dart';

class ReceiptForm extends StatefulWidget {
  final ReceiptsCompanion receipt;
  final sharedPrefs;
  final bool sendImage;
  final DbBloc _bloc;

  ReceiptForm(this.receipt, this.sendImage, this.sharedPrefs, this._bloc);

  @override
  ReceiptInputController createState() {
    return ReceiptInputController(receipt, sendImage, this.sharedPrefs, _bloc);
  }
}

class ReceiptInputController extends State<ReceiptForm> {
  final _formKey = GlobalKey<FormState>();
  final _dropKey = GlobalKey<FormState>();
  final SharedPreferences sharedPrefs;
  final DbBloc _bloc;

  TextEditingController storeNameController;
  TextEditingController receiptTotalController;
  TextEditingController dateController;

  String shopName;
  String total;
  bool sendImage;
  String receiptCategory;

  DateTime receiptDate;
  ReceiptsCompanion parsedReceipt;
  ReceiptCategory selectedCategory;

  ReceiptInputController(
      this.parsedReceipt, this.sendImage, this.sharedPrefs, this._bloc);

  @override
  void initState() {
    String initialStoreName = "";
    String initialTotalName = "";
    String initialDateController = "";

    if (parsedReceipt != null) {
      initialStoreName = parsedReceipt.shop.value ?? '';
      initialTotalName = parsedReceipt.total.value ?? '';
    }

    storeNameController = TextEditingController(text: initialStoreName);
    receiptTotalController = TextEditingController(text: initialTotalName);
    dateController = TextEditingController(text: initialDateController);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      if (parsedReceipt != null && parsedReceipt.date.value != null)
        dateController.text =
            DateManipulator.humanDate(context, parsedReceipt.date.value);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => showUpdateSuccess());
    return BlocBuilder(
      cubit: _bloc,
      builder: (BuildContext context, state) {
        if (state is LoadingState) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is ErrorState) {
          return Center(
            child: Text(S.of(context).receiptLoadFailed),
          );
        }
        if (state is LoadedState) {
          final receipt = state.receipt;
          return BlocProvider(
              create: (_) => _bloc,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                            child: Container(
                                child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Stack(children: <Widget>[
                                new Align(
                                    alignment: Alignment.bottomLeft,
                                    child: new GestureDetector(
                                        onLongPress: () {
                                          ReceiptGenerator generator =
                                              ReceiptGenerator(context);
                                          generator.init();
                                          for (int i = 0; i < 1000; i++) {
                                            ReceiptsCompanion c =
                                                generator.get();
                                            _bloc.add(InsertEvent(receipt: c));
                                          }
                                          _bloc.add(ReceiptAllFetch());
                                        },
                                        child: BannerFactory.get(
                                            S.of(context).addReceipt,
                                            context))),
                                Padding(
                                    padding: EdgeInsets.only(
                                        top: DimensionsCalculator
                                                .getBannerHeight(context) -
                                            30,
                                        right: 16),
                                    child: Align(
                                        alignment: Alignment.topRight,
                                        child: IconButton(
                                          icon: new Icon(Icons.camera_alt,
                                              size: 40, color: Colors.black),
                                          color: Colors.white,
                                          onPressed: () async {
                                            WidgetsFlutterBinding
                                                .ensureInitialized();

                                            final cameras =
                                                await availableCameras();
                                            final firstCamera = cameras.first;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TakePictureScreen(
                                                        sharedPrefs:
                                                            sharedPrefs,
                                                        camera: firstCamera),
                                              ),
                                            );
                                          },
                                        ))),
                              ]),
                              PaddingFactory.create(new Theme(
                                  data: AppTheme.lightTheme,
                                  child: TextFormFactory.storeName(
                                      storeNameController, context, receipt))),
                              PaddingFactory.create(new Theme(
                                  data: AppTheme.lightTheme,
                                  child: TextFormFactory.total(
                                      receiptTotalController, context))),
                              PaddingFactory.create(new Theme(
                                  data: AppTheme.lightTheme,
                                  child: TextFormField(
                                    style: TextStyle(color: Colors.black),
                                    decoration: new InputDecoration(
                                        enabledBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.grey),
                                        ),
                                        border: new OutlineInputBorder(
                                            borderSide: new BorderSide(
                                                color: Colors.grey)),
                                        hintText:
                                            S.of(context).receiptDateFormat,
                                        labelText:
                                            S.of(context).receiptDateLabelText,
                                        helperText:
                                            S.of(context).receiptDateHelperText,
                                        prefixIcon: IconButton(
                                            icon: Icon(
                                              Icons.calendar_today,
                                              color: Colors.red[350],
                                            ),
                                            splashColor: Colors.black,
                                            color: Colors.black,
                                            onPressed: () async {
                                              receiptDate =
                                                  await showDatePicker(
                                                      builder:
                                                          (BuildContext context,
                                                              Widget child) {
                                                        return Theme(
                                                          data:
                                                              ThemeData.light()
                                                                  .copyWith(
                                                            primaryColor:
                                                                Colors.black,
                                                            accentColor:
                                                                Colors.black,
                                                            colorScheme:
                                                                ColorScheme.light(
                                                                    primary:
                                                                        (Colors
                                                                            .red)),
                                                            buttonTheme:
                                                                ButtonThemeData(
                                                                    textTheme:
                                                                        ButtonTextTheme
                                                                            .primary),
                                                          ),
                                                          child: child,
                                                        );
                                                      },
                                                      context: context,
                                                      initialDate:
                                                          DateTime.now(),
                                                      firstDate: DateTime(2010),
                                                      lastDate: DateTime(2050));
                                              dateController.text = DateFormat(S
                                                      .of(context)
                                                      .receiptDateFormat)
                                                  .format(receiptDate);
                                            })),
                                    controller: dateController,
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return S.of(context).receiptDateDialog;
                                      }

                                      try {
                                        var format = DateFormat(
                                            S.of(context).receiptDateFormat);
                                        receiptDate = format.parse(value);
                                        return null;
                                      } catch (_) {
                                        receiptDate = null;
                                        return S
                                                .of(context)
                                                .receiptDateNotFormatted +
                                            " " +
                                            S.of(context).receiptDateFormat;
                                      }
                                    },
                                  ))),
                              PaddingFactory.create(Container(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, right: 8.0),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.grey)),
                                  child: Theme(
                                      data: AppTheme.lightTheme,
                                      child: DropdownButton<ReceiptCategory>(
                                          key: _dropKey,
                                          hint: Text(S
                                              .of(context)
                                              .receiptSelectCategory),
                                          value: selectedCategory,
                                          isExpanded: true,
                                          onChanged: (ReceiptCategory value) {
                                            setState(() {
                                              receiptCategory = value.name;
                                              selectedCategory = value;
                                            });
                                          },
                                          dropdownColor: Colors.white,
                                          items: ReceiptCategoryFactory.get(
                                                  context)
                                              .map((ReceiptCategory user) {
                                            return DropdownMenuItem<
                                                ReceiptCategory>(
                                              value: user,
                                              child: Row(
                                                children: <Widget>[
                                                  user.icon,
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  Text(
                                                    user.name,
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList())))),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    new Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child:
                                            ToggleSwitch(
                                              minWidth: 90.0,
                                              initialLabelIndex: 0,
                                              activeFgColor: Colors.white,
                                              inactiveBgColor: Colors.black,
                                              inactiveFgColor: Colors.white,
                                              labels: [S.of(context).outcome, S.of(context).income],
                                              activeBgColors: [Colors.blueAccent, Colors.red],
                                              onToggle: (index) {
                                                print('switched to: $index');
                                              },
                                            ))),
                                    new Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: submitButton())),
                                  ],
                                )

                            ],
                          ),
                        ))),
                      ],
                    ),
                  ),
                ],
              ));
        }
        return Container(
            color: Colors.white,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                boxShadow: <BoxShadow>[
                  BoxShadow(offset: Offset(0, 5), blurRadius: 10)
                ]));
      },
    );
  }

  FloatingActionButton submitButton() {
    return new FloatingActionButton(
        onPressed: () {
          final form = _formKey.currentState;
          // disable form validation for now
          if (form.validate() || receiptCategory != null) {
            try {
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(S.of(context).addReceipt),
                backgroundColor: Colors.green,
              ));
              shopName = storeNameController.text;
              total = receiptTotalController.text;
            } catch (e) {
              reset();
              return;
            }

            // trim negligent whitespaces
            shopName = shopName.trim();
            total = total.trim();

            _bloc.add(InsertEvent(
                receipt: ReceiptsCompanion(
                    date: Value(receiptDate),
                    total: Value(total),
                    category: Value(jsonEncode(selectedCategory)),
                    shop: Value(shopName))));
            _bloc.add(ReceiptAllFetch());

            bool _submitTrainingData = sharedPrefs.getBool("sendTrainingData");
            if (_submitTrainingData != null && _submitTrainingData == true && sendImage) {
              String ip = sharedPrefs.get("ipv4");
              String token = sharedPrefs.get("api_token");
              NetworkClient.sendTrainingData(ip, token, shopName, receiptDate.toIso8601String(), total, context);
            }

            reset();
          } else {
            if (receiptCategory == null || receiptCategory.isEmpty) {
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(S.of(context).receiptSelectCategory),
                  backgroundColor: Colors.red));
            } else {
              Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(S.of(context).invalidInput),
                  backgroundColor: Colors.red));
            }
          }
        },
        child: Icon(Icons.done_all));
  }

  void showUpdateSuccess() {
    if (sendImage) {
      if (parsedReceipt == null) {
        Scaffold.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(S.of(context).uploadFailed),
            backgroundColor: Colors.red,
          ));
      } else {
        Scaffold.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(S.of(context).uploadSuccess),
            backgroundColor: Colors.green,
          ));
      }
    }
  }

  void reset() {
    receiptTotalController.clear();
    storeNameController.clear();
    dateController.clear();
  }
}
