import 'package:clean_chess/core/utilities/enums.dart';

// PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningFamily,OpeningVariation
class Puzzle {
  // 8,
  // r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24,
  // f2g3 e6e7 b2b1 b3c1 b1c1 h6c1,
  // 1736,
  // 78,
  // 95,
  // 3012,
  // crushing hangingPiece long middlegame,
  // https://lichess.org/787zsVup/black#48,
  late final String id;
  late final String fen;
  late final Iterable<String> moves;
  late final int rating;
  late final String title;
  late final PieceColor turnColor;

  Puzzle.fromString({required String csvItem}) {
    final List<String> csvItemSplit = csvItem.split(',');
    id = csvItemSplit[0].padLeft(4, '0');
    fen = csvItemSplit[1];
    moves = csvItemSplit[2].split(' ');
    rating = int.parse(csvItemSplit[3]);
    title = csvItemSplit[7];
    turnColor = fen.split(' ')[1] == 'w' ? PieceColor.white : PieceColor.black;
  }
}