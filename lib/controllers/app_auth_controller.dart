import 'dart:async';
import 'dart:io';

import 'package:auth/models/app_responce_model.dart';
import 'package:auth/models/user.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.userName == null || user.password == null) {
      return Response.badRequest(
          body:
              AppResponceModel(error: 'userName or password is null').toJson());
    }

    final User fetchedUser = User();
    //Connect to DB
    // Find User
    // Verify Password
    // Create and return accessToken

    return Response.ok(AppResponceModel(data: {
      'id': fetchedUser.id,
      'refreshToken': fetchedUser.refreshToken,
      'accessToken': fetchedUser.accessToken
    }, message: 'signIn successful')
        .toJson());
  }

  //Connect to DB
  // Create User
  // Fetch User

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.userName == null || user.password == null || user.email == null) {
      return Response.badRequest(
          body:
              AppResponceModel(error: 'userName or password or email is null'));
    }

    final salt = generateRandomSalt();
    final hashedPassword = generatePasswordHash(user.password ?? "", salt);

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.userName = user.userName
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashedPassword;

        final createdUser = await qCreateUser.insert();
        id = createdUser.asMap()["id"];
        //final Map<String, dynamic> tokens = _getTokens(id);
        await _updateTokens(id, transaction);
      });

      final userData = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(AppResponceModel(
          data: userData?.backing.contents, message: 'signUp successful'));
    } on QueryException catch (error) {
      return Response.serverError(body: AppResponceModel(error: error.message));
    }
  }

  Future<void> _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, dynamic> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((user) => user.id).equalTo(id)
      ..values.accessToken = tokens["access"]
      ..values.refreshToken = tokens["refresh"];
    await qUpdateTokens.updateOne();
  }

  // connect to DB
  // find user
  // check token
  //fetch user
  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    User fetchedUser = User();
    return Response.ok(AppResponceModel(data: {
      'id': fetchedUser.id,
      'refreshToken': fetchedUser.refreshToken,
      'accessToken': fetchedUser.accessToken
    }, message: 'Refresh token successful')
        .toJson());
  }

  Map<String, dynamic> _getTokens(int id) {
    // TODO: Remove when release
    final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
    final accessClaimSet = JwtClaim(
      maxAge: Duration(hours: 1),
      otherClaims: {"id": id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {"id": id},
    );
    final tokens = <String, dynamic>{};
    tokens['accessToken'] = issueJwtHS256(accessClaimSet, key);
    tokens['refreshToken'] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }
}
