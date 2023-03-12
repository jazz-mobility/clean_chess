import 'package:cleanchess/chess/error/failures.dart';
import 'package:cleanchess/chess/utilities/extensions.dart';
import 'package:cleanchess/core/presentation/bloc/utilities/oauth_helper.dart'
    as oauth_helper;
import 'package:cleanchess/core/usecases/usecase.dart';
import 'package:cleanchess/core/utilities/mixins/access_token_provider.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/account/account.dart';
import 'package:cleanchess/features/clean_chess/presentation/bloc/lichess_event.dart';
import 'package:cleanchess/features/clean_chess/presentation/bloc/lichess_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/oauth/oauth.dart';

class LichessBloc extends Bloc<LichessEvent, LichessState> {
  final LichessTokenProvider tokenProvider;

  final LichessOAuth oauth;
  final LichessGainAccessToken gainAccessToken;
  final GetMyProfile getMyProfile;
  final GetMyEmail getMyEmail;
  final GetMyKidModeStatus getMyKidModeStatus;

  LichessBloc({
    required this.tokenProvider,
    required this.oauth,
    required this.gainAccessToken,
    required this.getMyProfile,
    required this.getMyEmail,
    required this.getMyKidModeStatus,
  }) : super(LichessInitial()) {
    on<LichessOAuthEvent>(_oauthProcedure);
    on<GetMyProfileEvent>((event, emit) async {
      emit(LichessLoading());
      final user = await getMyProfile.call(NoParams());

      user.fold(
        (failure) => emit(LichessError(failure)),
        (user) => emit(LichessUserFetched(user)),
      );
    });
    on<GetMyEmailEvent>((event, emit) async {
      emit(LichessLoading());
      final email = await getMyEmail.call(NoParams());

      email.fold(
        (failure) => emit(LichessError(failure)),
        (email) => emit(LichessLoaded<String>(email)),
      );
    });
    on<GetMyKidModeStatusEvent>((event, emit) async {
      emit(LichessLoading());
      final kidModeStatus = await getMyKidModeStatus.call(NoParams());

      kidModeStatus.fold(
        (failure) => emit(LichessError(failure)),
        (kidModeStatus) => emit(LichessLoaded<bool>(kidModeStatus)),
      );
    });
  }

  void _oauthProcedure(
    LichessOAuthEvent event,
    Emitter<LichessState> emit,
  ) async {
    emit(LichessLoading());

    // Generate an authorization URL that asks for the oauth2 permission
    const clientId = 'cleanchess';
    final grant = oauth_helper.getAuthorizationCodeGrant(
      clientId: clientId,
      oauthUri: 'https://lichess.org/oauth',
      tokenUri: 'https://lichess.org/api/token',
    );

    // Generate a random StateVerifier for the authorization request
    final stateVerifier = oauth_helper.getRandomVerifier;

    // Create a callback URL that will be used by the authorization server
    // to redirect the user back to the app with the authorization code
    const redirectUri = 'com.example.cleanchess://authorize';

    try {
      // Perform the authorization request
      final data = await oauth.call(
        LichessOAuthParams(
          grant: grant,
          stateVerifier: stateVerifier,
          redirectUri: redirectUri,
        ),
      );

      if (data.isLeft()) {
        emit(LichessError(data.left));
        return;
      }

      // Extract the authorization parameters from the response
      final OAuthParams params = data.right;

      // Exchange the authorization code for an access token
      final accessToken = await gainAccessToken.call(
        LichessGainAccessTokenParams(grant: grant, parameters: params),
      );

      if (accessToken.isLeft()) {
        emit(LichessError(accessToken.left));
        return;
      }

      // Save the access token
      await tokenProvider.saveAccessToken(accessToken.right);

      emit(const LichessOAuthSuccess());
    } catch (e) {
      emit(LichessError(UnexpectedFailure(e.toString())));
    }
  }
}
