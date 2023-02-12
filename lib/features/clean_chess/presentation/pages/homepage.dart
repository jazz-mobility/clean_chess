import 'package:clean_chess/core/utilities/enums.dart';
import 'package:clean_chess/features/clean_chess/data/models/board.dart';
import 'package:clean_chess/features/clean_chess/data/models/piece.dart';
import 'package:clean_chess/features/clean_chess/data/models/square.dart';
import 'package:clean_chess/features/clean_chess/presentation/bloc/board_bloc.dart';
import 'package:clean_chess/features/clean_chess/presentation/bloc/board_event.dart';
import 'package:clean_chess/features/clean_chess/presentation/bloc/board_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Homepage extends StatelessWidget {
  const Homepage({
    super.key,
    required this.board,
  });

  final Board board;

  @override
  Widget build(BuildContext context) {
    board.squares[4][4].piece = King(color: PieceColor.white);
    // board.squares[7][7].piece = Rook(color: PieceColor.white);
    // board.squares[7][0].piece = Rook(color: PieceColor.white);
    board.squares[2][4].piece = Pawn(color: PieceColor.black);
    // board.squares[4][4].piece!.totalMoves = 1;
    // board.squares[4][3].piece = Pawn(color: PieceColor.white);
    // board.squares[4][3].piece!.totalMoves = 1;
    board.squares[3][3].blackControl++;
    board.squares[3][5].blackControl++;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Clean Chess',
          style: TextStyle(
            fontSize: 26,
          ),
        ),
        centerTitle: true,
      ),
      body: _body(context),
    );
  }

  Widget _body(context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: _board(context),
      ),
    );
  }

  Widget _board(context) {
    return BlocConsumer<BoardBloc, BoardState>(
      listener: (context, state) {
        print(state);
      },
      builder: (_, state) {
        return GridView.count(
          crossAxisCount: 8,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(64, (index) {
            final square = board.squares[index ~/ 8][index % 8];
            return Container(
              decoration: BoxDecoration(
                color: getColor(index, state, square.coord),
                border: Border.all(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  _cellName(square.coord),
                  if (square.piece != null) _piece(square, context),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _cellName(String coord) => Positioned(
        bottom: 2,
        left: 2,
        child: Text(
          coord,
          style: TextStyle(
            color: Colors.grey.shade200,
            fontSize: 12,
          ),
        ),
      );

  Widget _piece(Square square, context) => SizedBox(
        width: 90,
        height: 90,
        child: MaterialButton(
          onPressed: () {
            BlocProvider.of<BoardBloc>(context)
                .add(PieceSelectedEvent(square.coord));
          },
          padding: EdgeInsets.zero,
          child: Image.asset(
            square.piece!.imagePath,
          ),
        ),
      );

  Color getColor(int index, BoardState state, String squareCoord) {
    if (state is BoardPlaning) {
      if (state.interactableSquares.map((e) => e.coord).contains(squareCoord)) {
        return Colors.red.shade700;
      }
    }
    int cellColor = (index % 2);
    int row = (index ~/ 8) % 2;
    if (row == 0) {
      cellColor = (index % 2) == 0 ? 1 : 0;
    }
    return cellColor == 0 ? Colors.grey.shade700 : Colors.grey.shade800;
  }
}