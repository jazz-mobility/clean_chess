import 'package:cleanchess/features/clean_chess/domain/usecases/account/account.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/oauth/lichess/lichess_oauth_lib.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/teams/teams.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

class MLichessOAuth extends Mock implements LichessOAuth {}

class MLichessGainAccessToken extends Mock implements LichessGainAccessToken {}

class MGetMyProfile extends Mock implements GetMyProfile {}

class MGetMyEmail extends Mock implements GetMyEmail {}

class MGetMyKidModeStatus extends Mock implements GetMyKidModeStatus {}

class MSetMyKidModeStatus extends Mock implements SetMyKidModeStatus {}

class MGetMyPreferences extends Mock implements GetMyPreferences {}

class MGetTeamsByUser extends Mock implements GetTeamsByUser {}

class MGetTeamById extends Mock implements GetTeamById {}

@GenerateNiceMocks([
  MockSpec<MLichessOAuth>(),
  MockSpec<MLichessGainAccessToken>(),
  MockSpec<MGetMyProfile>(),
  MockSpec<MGetMyEmail>(),
  MockSpec<MGetMyKidModeStatus>(),
  MockSpec<MSetMyKidModeStatus>(),
  MockSpec<MGetMyPreferences>(),
  MockSpec<MGetTeamsByUser>(),
  MockSpec<MGetTeamById>(),
])
void main() {}
