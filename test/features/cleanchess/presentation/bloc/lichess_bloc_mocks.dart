import 'package:cleanchess/features/clean_chess/domain/usecases/account/account.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/oauth/lichess/lichess_oauth_lib.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/teams/teams.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/users/get_realtime_user_status.dart';
import 'package:cleanchess/features/clean_chess/domain/usecases/users/users.dart';
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

class MGetTeamMembers extends Mock implements GetTeamMembers {}

class MGetTeamJoinRequests extends Mock implements GetTeamJoinRequests {}

class MAcceptJoinRequest extends Mock implements AcceptJoinRequest {}

class MDeclineJoinRequest extends Mock implements DeclineJoinRequest {}

class MKickMemberFromTeam extends Mock implements KickMemberFromTeam {}

class MJoinTeam extends Mock implements JoinTeam {}

class MLeaveTeam extends Mock implements LeaveTeam {}

class MMessageAllMembers extends Mock implements MessageAllMembers {}

class MSearchTeamByName extends Mock implements SearchTeamByName {}

class MGetPopularTeams extends Mock implements GetPopularTeams {}

class MGetUsersByTerm extends Mock implements GetUsersByTerm {}

class MGetUsernamesByTerm extends Mock implements GetUsernamesByTerm {}

class MGetRealtimeStatus extends Mock implements GetRealtimeStatus {}

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
  MockSpec<MGetTeamMembers>(),
  MockSpec<MGetTeamJoinRequests>(),
  MockSpec<MAcceptJoinRequest>(),
  MockSpec<MDeclineJoinRequest>(),
  MockSpec<MKickMemberFromTeam>(),
  MockSpec<MJoinTeam>(),
  MockSpec<MLeaveTeam>(),
  MockSpec<MMessageAllMembers>(),
  MockSpec<MSearchTeamByName>(),
  MockSpec<MGetPopularTeams>(),
  MockSpec<MGetUsersByTerm>(),
  MockSpec<MGetUsernamesByTerm>(),
  MockSpec<MGetRealtimeStatus>(),
])
void main() {}
