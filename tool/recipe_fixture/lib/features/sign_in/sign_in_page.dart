import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:adaptive_units/adaptive_units.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_app/features/sign_in/bloc/sign_in_bloc.dart';
import 'package:recipe_app/features/sign_in/model/session_model.dart';
import 'package:recipe_app/networking/api_response.dart';
import 'package:recipe_app/redux/actions.dart';
import 'package:recipe_app/redux/app_state.dart';
import 'package:recipe_app/resources/res_colors.dart';
import 'package:recipe_app/utils/extensions/context_ext.dart';
import 'package:recipe_app/utils/extensions/exception_ext.dart';
import 'package:recipe_app/utils/router/routes.dart';
import 'package:recipe_app/utils/widgets/ui/common_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => SignInPageState();
}

// recipe-block: 1
