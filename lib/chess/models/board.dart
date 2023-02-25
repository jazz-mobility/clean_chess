import 'package:clean_chess/chess/abstractions/piece.dart';
import 'package:clean_chess/chess/error/failures.dart';
import 'package:clean_chess/chess/models/cell.dart';
import 'package:clean_chess/chess/models/fen.dart';
import 'package:clean_chess/chess/models/move.dart';
import 'package:clean_chess/chess/models/pieces.dart';
import 'package:clean_chess/chess/utilities/extensions.dart';
import 'package:clean_chess/chess/utilities/utils.dart';
import 'package:clean_chess/chess/core/utilities/enums.dart';
import 'package:clean_chess/chess/core/utilities/extensions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

class Board {
  late final Iterable<Iterable<Cell>> _board;
  Move? _lastMove;

  /// Total amount of known moves
  /// -1 because of initial position
  ///
  /// Known moves are moves that are stored in [_knownMovesFen]
  /// If the board was build from a FEN during a game,
  /// the moves before the FEN are not known
  final List<String> _knownMovesFen = [];
  int get totalKnownMoves => _knownMovesFen.length - 1;

  int _halfmoveClock = 0;
  int get halfmoveClock => _halfmoveClock;

  int _fullmoveNumber = 1;
  int get fullmoveNumber => _fullmoveNumber;

  Iterable<Cell> get cells => _board.expand((element) => element);

  final String _rowNames = 'abcdefgh';

  Board.empty() {
    List<List<Cell>> cells = [];
    for (int column = 8; column > 0; column--) {
      for (int row = 0; row < 8; row++) {
        int index = (column - 1) * 8 + row;
        cells.add([
          Cell(
            index,
            _rowNames[row] + column.toString(),
          ),
        ]);
      }
    }
    _board = cells;
  }

  Board.clone(Board board) {
    _board = board._board.map((e) => e.map((e) => Cell.clone(e)).toList());
    _knownMovesFen.addAll(board._knownMovesFen);
  }

  Board.fromFen(Fen fen) {
    // r6k/pp2r2p/4Rp1Q/3p4/8/1N1P2R1/PqP2bPP/7K b - - 0 24,
    final emptyBoard = Board.empty();
    final rows = fen.positions.split('/');

    // Positions
    for (int column = 8; column > 0; column--) {
      final currentRow = rows[8 - column];
      int currentCell = 0;
      for (int row = 0; row < currentRow.length; row++) {
        final currentLetter = currentRow[row];
        final number = int.tryParse(currentLetter);
        if (number != null) {
          // Empty spaces
          currentCell += number;
        } else {
          final piece = getPieceFromFen(currentLetter);
          if (piece.isLeft()) throw Exception(piece.left);

          (piece.right as Piece).setMovesFromFen();
          final coord = _rowNames[currentCell] + column.toString();
          emptyBoard._board
              .expand((element) => element)
              .firstWhere((element) => element.coord == coord)
              .piece = piece.right;

          currentCell++;
        }
      }
    }

    _board = emptyBoard._board;

    _knownMovesFen.add(positionsGen());

    _calculateControlledCells();

    // Castling
    _setCastlingRightsFromFen(fen.castlingRights);

    // En passant
    _setEnPassantRightsFromFen(fen.enPassantSquare);

    // Halfmove clock
    _halfmoveClock = fen.halfmoveClock;

    // Fullmove number
    _fullmoveNumber = fen.fullmoveNumber;
  }

  void _setCastlingRightsFromFen(String castlingRights) {
    if (castlingRights != '-') {
      final whiteQueenSide = castlingRights.contains('Q');
      final whiteKingSide = castlingRights.contains('K');
      if (whiteQueenSide || whiteKingSide) {
        final cell = getCell('e1');
        if (cell.isLeft()) throw Exception(cell.left);

        if (cell.right.piece is! King) throw InvalidFen();

        (cell.right.piece! as King).setCastlingRightFromFen();
        if (whiteQueenSide) {
          final cell = getCell('a1');
          if (cell.isLeft()) throw Exception(cell.left);

          if (cell.right.piece is! Rook) throw InvalidFen();

          (cell.right.piece! as Rook).setCastlingRightFromFen();
        }
        if (whiteKingSide) {
          final cell = getCell('h1');
          if (cell.isLeft()) throw Exception(cell.left);

          if (cell.right.piece is! Rook) throw InvalidFen();

          (cell.right.piece! as Rook).setCastlingRightFromFen();
        }
      }

      final blackQueenSide = castlingRights.contains('q');
      final blackKingSide = castlingRights.contains('k');
      if (blackQueenSide || blackKingSide) {
        final cell = getCell('e8');
        if (cell.isLeft()) throw Exception(cell.left);

        if (cell.right.piece is! King) throw InvalidFen();

        (cell.right.piece! as King).setCastlingRightFromFen();
        if (blackQueenSide) {
          final cell = getCell('a8');
          if (cell.isLeft()) throw Exception(cell.left);

          if (cell.right.piece is! Rook) throw InvalidFen();

          (cell.right.piece! as Rook).setCastlingRightFromFen();
        }
        if (blackKingSide) {
          final cell = getCell('h8');
          if (cell.isLeft()) throw Exception(cell.left);

          if (cell.right.piece is! Rook) throw InvalidFen();

          (cell.right.piece! as Rook).setCastlingRightFromFen();
        }
      }
    }
  }

  void _setEnPassantRightsFromFen(String enPassantSquare) {
    if (enPassantSquare != '-') {
      final maybeCell = getCell(enPassantSquare);
      if (maybeCell.isLeft()) throw Exception(maybeCell.left);

      final cell = maybeCell.right as Cell;

      if (cell.piece != null) throw InvalidFen();

      if (cell.row == 3 || cell.row == 6) {
        final startRow = cell.row == 3 ? 2 : 7;
        final cellStart = getCell('${cell.column}$startRow');
        if (cellStart.isLeft()) throw Exception(cellStart.left);

        final endRow = cell.row == 3 ? 4 : 5;
        final cellEnd = getCell('${cell.column}$endRow');
        if (cellEnd.isLeft()) throw Exception(cellEnd.left);

        if (cellEnd.right.piece is! Pawn) throw InvalidFen();

        (cellEnd.right.piece! as Pawn).setEnPassantRightFromFen();

        _lastMove = Move(cellStart.right, cellEnd.right);
      }
    }
  }

  void _calculateControlledCells() {
    final cellsWithPieces = cells.where((element) => element.piece != null);
    List<Cell> cellsWithKing = [];
    for (final cell in cellsWithPieces) {
      if (cell.piece is King) {
        cellsWithKing.add(cell);
        continue;
      }

      final moves = controlledCells(cell);
      if (moves.isLeft()) throw Exception(moves.left);

      for (final Cell targetCell in moves.right) {
        targetCell.addControl(cell.piece!.color);
      }
    }

    for (final cell in cellsWithKing) {
      final moves = controlledCells(cell);
      if (moves.isLeft()) throw Exception(moves.left);

      for (final targetCell in moves.right) {
        targetCell.addControl(cell.piece!.color);
      }
    }
  }

  String positionsGen() {
    String fen = '';
    for (int column = 8; column > 0; column--) {
      int emptySpaces = 0;
      for (int row = 0; row < 8; row++) {
        final coord = _rowNames[row] + column.toString();
        final cell = getCell(coord);
        if (cell.isLeft()) throw Exception(cell.left);
        if (cell.right.piece == null) {
          emptySpaces++;
        } else {
          if (emptySpaces > 0) {
            fen += emptySpaces.toString();
            emptySpaces = 0;
          }
          fen += cell.right.piece!.toFen;
        }
      }
      if (emptySpaces > 0) {
        fen += emptySpaces.toString();
        emptySpaces = 0;
      }
      if (column > 1) {
        fen += '/';
      }
    }

    return fen;
  }

  Either<Failure, Cell> getCell(String coord) {
    final cell = _board
        .expand((element) => element)
        .firstWhereOrNull((element) => element.coord == coord);
    return cell != null
        ? Right(cell)
        : Left(PieceNotFoundOnCellFailure('No piece found on $coord'));
  }

  Either<Failure, Empty> setPiece({
    required String coord,
    required Piece piece,
  }) {
    final cell = getCell(coord);
    if (cell.isLeft()) {
      return cell.left;
    }
    cell.right.piece = piece;
    return const Right(Empty());
  }

  Either<Failure, Iterable<Cell>> planPath(Cell cell) {
    final pathPlanners = {
      Pawn: getPawnMoves,
      Rook: getRookMoves,
      Knight: getKnightMoves,
      Bishop: getBishopMoves,
      Queen: getQueenMoves,
      King: getKingMoves,
    };

    return pathPlanners[cell.piece!.runtimeType]!(cell);
  }

  Either<Failure, Iterable<Cell>> controlledCells(Cell cell) {
    final pathPlanners = {
      Pawn: getPawnMoves,
      Rook: getRookMoves,
      Knight: getKnightMoves,
      Bishop: getBishopMoves,
      Queen: getQueenMoves,
      King: getKingMoves,
    };

    return pathPlanners[cell.piece!.runtimeType]!(cell, calculateControl: true);
  }

  Either<Failure, Empty> movePiece(Move move) {
    final piece = move.from.piece;
    if (piece == null) {
      return Left(
        PieceNotFoundOnCellFailure('No piece found on ${move.from.coord}'),
      );
    }

    final moves = planPath(move.from);
    if (moves.isLeft()) return moves.left;

    final cells = moves.right as Iterable<Cell>;

    final targetCell = cells.firstWhereOrNull(
      (element) => element.coord == move.to.coord,
    );

    if (targetCell == null) {
      return Left(
        InvalidMoveFailure(
          'Invalid move from ${move.from.coord} to ${move.to.coord}',
        ),
      );
    }

    if (targetCell.piece?.color == piece.color) {
      return Left(
        InvalidMoveFailure(
          'Invalid move from ${move.from.coord} to ${move.to.coord}',
        ),
      );
    }

    _lastMove = move;
    final movedPiece = move.from.piece!;

    // Update clocks
    if (movedPiece is Pawn || targetCell.piece != null) {
      _halfmoveClock = 0;
    } else {
      _halfmoveClock++;
    }

    if (movedPiece.color == PieceColor.black) {
      _fullmoveNumber++;
    }

    this.cells.firstWhere((element) => element.coord == move.to.coord).piece =
        movedPiece;
    this.cells.firstWhere((element) => element.coord == move.from.coord).piece =
        null;

    movedPiece.hasMoved();

    _knownMovesFen.add(positionsGen());

    for (final currentCell in this.cells) {
      currentCell.resetControl();
    }

    _calculateControlledCells();

    return const Right(Empty());
  }

  Either<Failure, String> getMove(int index) {
    if (index < 0 || index >= _knownMovesFen.length) {
      return Left(
        InvalidMoveIndexFailure('Invalid move index $index'),
      );
    }

    return Right(_knownMovesFen[index]);
  }

  Either<Failure, bool> canCastle({
    required PieceColor color,
    required bool isHColumn,
  }) {
    final king = cells.firstWhere(
      (element) => element.piece is King && element.piece!.color == color,
    );

    final castleRight = _getCastlingCells(king, isHColumn);
    if (castleRight.isLeft()) return castleRight.left;

    return Right((castleRight.right as Iterable<Cell>).isNotEmpty);
  }

  Either<Failure, String?> enPassantSquare() {
    if (_lastMove == null) return const Right(null);

    final lastCellMove = _lastMove!.to;

    if (lastCellMove.piece is! Pawn) return const Right(null);
    if ((lastCellMove.piece as Pawn).getMoveTimes != 1)
      return const Right(null);

    // Check if the pawn is in the correct row
    if (_lastMove!.to.row != 5 && _lastMove!.to.row != 4) {
      return const Right(null);
    }

    return Right(_lastMove!.from.coord);
  }

  //#region Piece Moves Helpers
  @visibleForTesting
  Either<Failure, Iterable<Cell>> getPawnMoves(
    Cell cell, {
    bool calculateControl = false,
  }) {
    // Get the reference cell from the board
    final maybeBoardCell = getCell(cell.coord);
    if (maybeBoardCell.isLeft()) return maybeBoardCell.left;

    final Cell boardCell = maybeBoardCell.right;

    // Asserts

    if (boardCell.piece == null) {
      return Left(
        PieceNotFoundOnCellFailure('No piece found on ${cell.coord}'),
      );
    }

    if (boardCell.piece is! Pawn) {
      return Left(
        UnexpectedPieceType('Expected Pawn, got ${boardCell.piece}'),
      );
    }

    // Get free cells in the direction of the pawn
    final moveLength = boardCell.piece!.getMoveTimes == 0 &&
            (boardCell.row == 2 || boardCell.row == 7)
        ? 2
        : 1;

    final pieceColor = boardCell.piece!.color;

    final direction = pieceColor == PieceColor.white
        ? StraightDirection.verticalTop
        : StraightDirection.verticalBottom;

    final freeCells = getFreeLinedCells(
      boardCell,
      moveLength,
      direction,
      boardCell.piece!.color,
    );

    if (freeCells.isLeft()) return freeCells.left;

    // Get the valid cells
    final validCells = (freeCells.right as Iterable<Cell>).toList();
    if (validCells.isNotEmpty && validCells.last.piece?.color == pieceColor) {
      validCells.removeLast();
    }

    if (calculateControl) {
      validCells.clear();
    }

    // Add diagonal moves
    final topRightCell = getFreeDiagonalCells(
      boardCell,
      1,
      pieceColor == PieceColor.white
          ? DiagonalDirection.topRight
          : DiagonalDirection.bottomRight,
      boardCell.piece!.color,
      calculateControl: calculateControl,
    );
    if (topRightCell.isLeft()) return topRightCell.left;
    final rightCells = (topRightCell.right as Iterable<Cell>);
    if (rightCells.isNotEmpty) {
      final rightCell = (topRightCell.right as Iterable<Cell>).first;
      final isEnemyRight =
          rightCell.piece != null && rightCell.piece?.color != pieceColor;
      if (isEnemyRight || calculateControl) {
        validCells.addAll((topRightCell.right as Iterable<Cell>));
      }
    }

    final topLeftCell = getFreeDiagonalCells(
      boardCell,
      1,
      pieceColor == PieceColor.white
          ? DiagonalDirection.topLeft
          : DiagonalDirection.bottomLeft,
      boardCell.piece!.color,
      calculateControl: calculateControl,
    );
    if (topLeftCell.isLeft()) return topLeftCell.left;
    final leftCells = (topLeftCell.right as Iterable<Cell>);
    if (leftCells.isNotEmpty) {
      final leftCell = (topLeftCell.right as Iterable<Cell>).first;
      final isEnemyLeft =
          leftCell.piece != null && leftCell.piece?.color != pieceColor;
      if (isEnemyLeft || calculateControl) {
        validCells.addAll((topLeftCell.right as Iterable<Cell>));
      }
    }

    // En passant
    if (pieceColor == PieceColor.white) {
      if (cell.row == 5 && cell.piece!.getMoveTimes == 2) {
        final leftCell =
            getCell("${_rowNames[_rowNames.indexOf(cell.column) - 1]}5");
        final rightCell =
            getCell("${_rowNames[_rowNames.indexOf(cell.column) + 1]}5");
        if (leftCell.isRight() && leftCell.right.piece is Pawn) {
          final pawn = leftCell.right.piece as Pawn;
          if (pawn.getMoveTimes == 1 && pawn.color == PieceColor.black) {
            final enPassantCell =
                getCell("${_rowNames[_rowNames.indexOf(cell.column) - 1]}6");
            if (enPassantCell.isRight()) {
              validCells.add(enPassantCell.right);
            }
          }
        }
        if (rightCell.isRight() && rightCell.right.piece is Pawn) {
          final pawn = rightCell.right.piece as Pawn;
          if (pawn.getMoveTimes == 1 && pawn.color == PieceColor.black) {
            final enPassantCell =
                getCell("${_rowNames[_rowNames.indexOf(cell.column) + 1]}6");
            if (enPassantCell.isRight()) {
              validCells.add(enPassantCell.right);
            }
          }
        }
      }
    } else {
      if (cell.row == 4 && cell.piece!.getMoveTimes == 2) {
        final leftCell =
            getCell("${_rowNames[_rowNames.indexOf(cell.column) - 1]}4");
        final rightCell =
            getCell("${_rowNames[_rowNames.indexOf(cell.column) + 1]}4");
        if (leftCell.isRight() && leftCell.right.piece is Pawn) {
          final pawn = leftCell.right.piece as Pawn;
          if (pawn.getMoveTimes == 1 && pawn.color == PieceColor.white) {
            final enPassantCell =
                getCell("${_rowNames[_rowNames.indexOf(cell.column) - 1]}3");
            if (enPassantCell.isRight()) {
              validCells.add(enPassantCell.right);
            }
          }
        }
        if (rightCell.isRight() && rightCell.right.piece is Pawn) {
          final pawn = rightCell.right.piece as Pawn;
          if (pawn.getMoveTimes == 1 && pawn.color == PieceColor.white) {
            final enPassantCell =
                getCell("${_rowNames[_rowNames.indexOf(cell.column) + 1]}3");
            if (enPassantCell.isRight()) {
              validCells.add(enPassantCell.right);
            }
          }
        }
      }
    }

    return Right(validCells);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getKnightMoves(
    Cell cell, {
    bool calculateControl = false,
  }) {
    final maybeBoardCell = getCell(cell.coord);
    if (maybeBoardCell.isLeft()) return maybeBoardCell.left;

    final boardCell = maybeBoardCell.right as Cell;

    // Asserts
    if (boardCell.piece == null) {
      return Left(
        PieceNotFoundOnCellFailure('No piece found on ${cell.coord}'),
      );
    }

    if (boardCell.piece is! Knight) {
      return Left(
        UnexpectedPieceType('Expected Knight, got ${boardCell.piece}'),
      );
    }

    List<Cell> cells = [];

    final pieceColor = boardCell.piece!.color;

    for (final currentDirectionCell in KnightDirection.values) {
      final currentRow = boardCell.row + currentDirectionCell.x;
      final currentColumn =
          _rowNames.indexOf(boardCell.column) + currentDirectionCell.y;

      if (currentRow < 1 || currentRow > 8) continue;
      if (currentColumn < 0 || currentColumn > 7) continue;

      final currentCell = getCell(
        '${_rowNames[currentColumn]}$currentRow',
      );
      if (currentCell.isLeft()) return currentCell.left;

      final currentBoardCell = currentCell.right as Cell;

      if (currentBoardCell.piece == null) {
        cells.add(currentBoardCell);
      } else if (currentBoardCell.piece?.color != pieceColor ||
          calculateControl) {
        cells.add(currentBoardCell);
      }
    }

    return Right(cells);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getBishopMoves(
    Cell cell, {
    bool ignorePieceTypeAssert = false,
    int directionLength = 7,
    bool calculateControl = false,
  }) {
    final maybeBoardCell = getCell(cell.coord);
    if (maybeBoardCell.isLeft()) return maybeBoardCell.left;

    final boardCell = maybeBoardCell.right as Cell;

    // Asserts
    if (boardCell.piece == null) {
      return Left(
        PieceNotFoundOnCellFailure('No piece found on ${cell.coord}'),
      );
    }

    if (!ignorePieceTypeAssert && boardCell.piece is! Bishop) {
      return Left(
        UnexpectedPieceType('Expected Bishop, got ${boardCell.piece}'),
      );
    }

    List<Cell> cells = [];

    final pieceColor = boardCell.piece!.color;

    // Top right
    final topRightCells = getFreeDiagonalCells(
      boardCell,
      directionLength,
      DiagonalDirection.topRight,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (topRightCells.isLeft()) return topRightCells.left;

    cells.addAll(topRightCells.right as Iterable<Cell>);

    // Top left
    final topLeftCells = getFreeDiagonalCells(
      boardCell,
      directionLength,
      DiagonalDirection.topLeft,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (topLeftCells.isLeft()) return topLeftCells.left;

    cells.addAll(topLeftCells.right as Iterable<Cell>);

    // Bottom right
    final bottomRightCells = getFreeDiagonalCells(
      boardCell,
      directionLength,
      DiagonalDirection.bottomRight,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (bottomRightCells.isLeft()) return bottomRightCells.left;

    cells.addAll(bottomRightCells.right as Iterable<Cell>);

    // Bottom left
    final bottomLeftCells = getFreeDiagonalCells(
      boardCell,
      directionLength,
      DiagonalDirection.bottomLeft,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (bottomLeftCells.isLeft()) return bottomLeftCells.left;

    cells.addAll(bottomLeftCells.right as Iterable<Cell>);

    return Right(cells);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getRookMoves(
    Cell cell, {
    bool ignorePieceTypeAssert = false,
    int directionLength = 7,
    bool calculateControl = false,
  }) {
    final maybeBoardCell = getCell(cell.coord);
    if (maybeBoardCell.isLeft()) return maybeBoardCell.left;

    final boardCell = maybeBoardCell.right as Cell;

    // Asserts
    if (boardCell.piece == null) {
      return Left(
        PieceNotFoundOnCellFailure('No piece found on ${cell.coord}'),
      );
    }

    if (!ignorePieceTypeAssert && boardCell.piece is! Rook) {
      return Left(
        UnexpectedPieceType('Expected Rook, got ${boardCell.piece}'),
      );
    }

    List<Cell> cells = [];

    final pieceColor = boardCell.piece!.color;

    // Top
    final topCells = getFreeLinedCells(
      boardCell,
      directionLength,
      StraightDirection.verticalTop,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (topCells.isLeft()) return topCells.left;

    cells.addAll(topCells.right as Iterable<Cell>);

    // Bottom
    final bottomCells = getFreeLinedCells(
      boardCell,
      directionLength,
      StraightDirection.verticalBottom,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (bottomCells.isLeft()) return bottomCells.left;

    cells.addAll(bottomCells.right as Iterable<Cell>);

    // Left
    final leftCells = getFreeLinedCells(
      boardCell,
      directionLength,
      StraightDirection.horizontalLeft,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (leftCells.isLeft()) return leftCells.left;

    cells.addAll(leftCells.right as Iterable<Cell>);

    // Right
    final rightCells = getFreeLinedCells(
      boardCell,
      directionLength,
      StraightDirection.horizontalRight,
      pieceColor,
      calculateControl: calculateControl,
    );
    if (rightCells.isLeft()) return rightCells.left;

    cells.addAll(rightCells.right as Iterable<Cell>);

    return Right(cells);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getQueenMoves(
    Cell cell, {
    bool calculateControl = false,
  }) {
    final horizontalCells = getRookMoves(
      cell,
      ignorePieceTypeAssert: true,
      calculateControl: calculateControl,
    );
    if (horizontalCells.isLeft()) return horizontalCells.left;

    final diagonalCells = getBishopMoves(
      cell,
      ignorePieceTypeAssert: true,
      calculateControl: calculateControl,
    );
    if (diagonalCells.isLeft()) return diagonalCells.left;

    return Right([...horizontalCells.right, ...diagonalCells.right]);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getKingMoves(
    Cell cell, {
    bool calculateControl = false,
  }) {
    final horizontalCells = getRookMoves(
      cell,
      ignorePieceTypeAssert: true,
      directionLength: 1,
      calculateControl: calculateControl,
    );
    if (horizontalCells.isLeft()) return horizontalCells.left;

    final diagonalCells = getBishopMoves(
      cell,
      ignorePieceTypeAssert: true,
      directionLength: 1,
      calculateControl: calculateControl,
    );
    if (diagonalCells.isLeft()) return diagonalCells.left;

    List<Cell> cells = [...horizontalCells.right, ...diagonalCells.right];

    // Add castling
    if (cell.piece!.getMoveTimes == 0) {
      final leftCastlingCells = _getCastlingCells(cell, false);
      if (leftCastlingCells.isLeft()) return leftCastlingCells.left;

      // Remove cells that are in the way of castling to avoid duplicates
      for (final currentCastlingCell
          in leftCastlingCells.right as Iterable<Cell>) {
        cells.removeWhere(
          (element) => element.coord == currentCastlingCell.coord,
        );
      }
      cells.addAll(leftCastlingCells.right as Iterable<Cell>);

      final rightCastlingCells = _getCastlingCells(cell, true);
      if (rightCastlingCells.isLeft()) return rightCastlingCells.left;

      // Remove cells that are in the way of castling to avoid duplicates
      for (final currentCastlingCell
          in rightCastlingCells.right as Iterable<Cell>) {
        cells.removeWhere(
          (element) => element.coord == currentCastlingCell.coord,
        );
      }
      cells.addAll(rightCastlingCells.right as Iterable<Cell>);
    }

    if (!calculateControl) {
      // Remove cells that are under attack
      cells.removeWhere(
        (element) => element.getEnemyControl(cell.piece!.color) > 0,
      );
    }

    return Right(cells);
  }

  //#endregion

  //#region Private Helpers

  Either<Failure, Iterable<Cell>> _getCastlingCells(
    Cell cellRef,
    bool rightDirection,
  ) {
    final isOnStartingPoint = cellRef.coord == 'e1' || cellRef.coord == 'e8';
    if (!isOnStartingPoint) return const Right([]);

    final pieceColor = cellRef.piece!.color;

    // Check if king is under attack
    if (cellRef.getEnemyControl(pieceColor) > 0) return const Right([]);

    final rook = getCell('${rightDirection ? 'h' : 'a'}${cellRef.row}');
    final canCastle = rook.isRight() &&
        rook.right.piece is Rook &&
        rook.right.piece.color == pieceColor &&
        rook.right.piece!.moveTimes == 0;
    if (!canCastle) return const Right([]);

    // Check if cells between king and rook are empty
    final cells = getFreeLinedCells(
      cellRef,
      2,
      rightDirection
          ? StraightDirection.horizontalRight
          : StraightDirection.horizontalLeft,
      pieceColor,
    );
    if (cells.isLeft()) return cells.left;

    final leftCellsAreEmpty =
        cells.right.every((Cell element) => element.piece == null);
    if (!leftCellsAreEmpty) return const Right([]);

    // Check if cells between king and rook are under attack
    final cellsUnderAttack = cells.right
        .where((Cell element) => element.getEnemyControl(pieceColor) > 0);
    if (cellsUnderAttack.isNotEmpty) return const Right([]);

    return Right(cells.right);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getFreeLinedCells(
    Cell cellRef,
    int moveLength,
    StraightDirection direction,
    PieceColor pieceColor, {
    bool calculateControl = false,
  }) {
    final isHorizontal = direction == StraightDirection.horizontalLeft ||
        direction == StraightDirection.horizontalRight;
    final lengthAmount =
        moveLength * (isHorizontal ? direction.x : direction.y);

    List<Cell> cells = [];
    for (int i = 1; i <= lengthAmount.abs(); i++) {
      late String currentCoord;
      if (isHorizontal) {
        final currentColumn =
            _rowNames.indexOf(cellRef.column) + (i * direction.x);
        if (currentColumn < 0 || currentColumn > 7) break;
        currentCoord = "${_rowNames[currentColumn]}${cellRef.row}";
      } else {
        final currentRow = cellRef.row + (i * direction.y);
        if (currentRow < 1 || currentRow > 8) break;
        currentCoord = "${cellRef.column}$currentRow";
      }
      final cell = _getCellFromCoord(currentCoord);
      if (cell.isLeft()) return cell.left;
      if (cell.right.piece != null) {
        if (cell.right.piece!.color != pieceColor || calculateControl) {
          cells.add(cell.right);
        }
        break;
      }

      cells.add(cell.right);
    }

    return Right(cells);
  }

  @visibleForTesting
  Either<Failure, Iterable<Cell>> getFreeDiagonalCells(
    Cell cellRef,
    int moveLength,
    DiagonalDirection direction,
    PieceColor pieceColor, {
    bool calculateControl = false,
  }) {
    List<Cell> cells = [];
    for (int i = 1; i <= moveLength; i++) {
      final currentRow = cellRef.row + (i * direction.y);
      final currentColumn =
          _rowNames.indexOf(cellRef.column) + (i * direction.x);
      if (currentRow < 1 || currentRow > 8) break;
      if (currentColumn < 0 || currentColumn > 7) break;
      final currentCoord = "${_rowNames[currentColumn]}$currentRow";
      final cell = _getCellFromCoord(currentCoord);
      if (cell.isLeft()) return cell.left;
      if (cell.right.piece != null) {
        if (cell.right.piece!.color != pieceColor || calculateControl) {
          cells.add(cell.right);
        }
        break;
      }

      cells.add(cell.right);
    }

    return Right(cells);
  }

  Either<Failure, Cell> _getCellFromCoord(String coord) {
    final cell = cells.firstWhereOrNull((e) => e.coord == coord);
    return cell != null
        ? Right(cell)
        : Left(CellNotFoundOnBoard('No cell found $coord'));
  }

  //#endregion
}
