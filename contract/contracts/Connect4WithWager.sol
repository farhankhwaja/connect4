// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";

contract Connect4WithWager is PermissionsEnumerable {
  struct Player {
    address payable playerAddress;
    uint8 playerColor;
    uint256 wager;
    uint8 moves;
  } 

  struct Game {
    Player[2] players;
    uint8[7][6] board;
    uint8 currentPlayer;
    address winner;
    uint wager;
    uint256 totalBet;
    bool started;
    bool ended;
    uint256 id;
  }

  Game[] public games;
  mapping(uint => Game) public gameToGameStruct;
  mapping(address => uint[]) public playerToGames;

  event GameCreated(address indexed player1, address indexed player2, uint gameId);
  event GameStarted(address indexed player1, address indexed player2, uint gameId);
  event GameEnded(address indexed player1, address indexed player2, uint gameId);
  event GameWon(address indexed winner, uint gameId);
  event GameDrawn(address indexed player1, address indexed player2, uint gameId);
  event WagerWithdrawn(address indexed player, uint gameId, uint amount);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function startGame(address _player2) public payable {
    uint id = games.length;
    require(playerToGames[msg.sender] < 2, "You already have multiple games in progress. Complete them first");
    require(playerToGames[_player2] < 2, "You already have multiple games in progress. Complete them first");

    games.push();
    Game storage newGame = games[id];
    newGame.players[0] = Player(payable(msg.sender), 1, msg.value);
    newGame.players[1] = Player(payable(_player2), 2, 0);
    newGame.currentPlayer = 0;
    
    gameToGameStruct[id] = newGame;
    newGame.wager = msg.value;
    newGame.totalBet = msg.value;
    newGame.started = false;
    emit GameCreated(msg.sender, _player2, id);
  }

  function joinGame(uint gameId) public payable {
    Game storage game = games[gameId];
    require(game.started == false, "Game has started");
    require(game.ended == false, "Game has ended");
    require(msg.value == game.wager, "You must match the wager to join the game");
    require(game.players[1].playerAddress == msg.sender, "Only the second player can join the game");
    game.players[1].wager = msg.value;
    game.totalBet += msg.value; // Double the wager now that both players have contributed
    game.started = true;
    emit GameStarted(game.players[0].playerAddress, msg.sender, gameId);
  }

  function makeMove(uint gameId, address playerAddress, uint8 _column) public {
    Game storage game = games[gameId];
    address payable currentPlayerAddr = game.players[game.currentPlayer].playerAddress;
    require(currentPlayerAddr == playerAddress, "It's not your turn");
    require(_column < 7, "Invalid column number");
    require(game.ended == false, "Game has ended");

    uint8 row = 5;
    while(game.board[row][_column] != 0){
      row--;
      require(row >= 0, "Column Full. Try Another");
    }
    game.board[row][_column] = uint8(game.currentPlayer + 1);
    game.players[game.currentPlayer].moves++;

    if (game.players[game.currentPlayer].moves >= 4) {
      if(checkWin(game.board, game.currentPlayer+1)){
        game.winner = currentPlayerAddr;
        uint256 winnerMoney = game.totalBet;
        game.totalBet = 0;
        payable(currentPlayerAddr).transfer(winnerMoney); // Give the wager to the winner
        game.ended = true;
        emit GameWon(msg.sender, game.id);
      } else if(checkDraw(game.board)){
        // In case of a draw, return the wager to both players
        uint256 refundWager = game.totalBet / 2;
        game.totalBet -= refundWager;
        game.players[0].playerAddress.transfer(refundWager);

        refundWager = game.totalBet;
        game.totalBet -= refundWager;
        game.players[1].playerAddress.transfer(refundWager);
        game.ended = true;
        emit GameDrawn(game.players[0].playerAddress, game.players[1].playerAddress, game.id);
      } else {
        game.currentPlayer = 1 - game.currentPlayer; 
      }
    } else {
      game.currentPlayer = 1 - game.currentPlayer; 
    }
  }

  function checkWin(uint8[7][6] memory _board, uint8 currentPlayer) private pure returns(bool){
      // Check horizontally
      for(uint i = 0; i<6; i++){
          for(uint j = 0; j<4; j++){
              if(_board[i][j] == currentPlayer && currentPlayer == _board[i][j+1] && currentPlayer == _board[i][j+2] && currentPlayer == _board[i][j+3]){
                  return true;
              }
          }
      }
      
      // Check vertically
      for(uint i = 0; i < 7;i++){
          for(uint j = 0; j < 3; j++){
              if(_board[j][i] == currentPlayer && currentPlayer == _board[j+1][i] && currentPlayer == _board[j+2][i] && currentPlayer == _board[j+3][i]){
                  return true;
              }
          }
      }

      // Check diagonally ascending
      for(uint i=0; i<3; i++){
          for(uint j=0; j<4; j++){
              if(_board[i][j] == currentPlayer && currentPlayer == _board[i+1][j+1] && currentPlayer == _board[i+2][j+2] && currentPlayer == _board[i+3][j+3]){
                  return true;
              }
          }
      }

      // Check diagonally (top left to bottom right)
      for(uint i=0; i<3; i++){
          for(uint j=0; j<4; j++){
              if(_board[i+3][j] == currentPlayer && currentPlayer == _board[i+1][j+2] && currentPlayer == _board[i+2][j+1] && currentPlayer == _board[i][j+3]){
                  return true;
              }
          }
      }

      return false;
  }

  function checkDraw(uint8[7][6] memory _board) private pure returns(bool){
      for(uint8 i = 0; i < 6; i++){
        for(uint8 j = 0; j < 7; j++){
            if(_board[i][j] == 0){
                return false;
            }
        }
      }
      return true;
  }

  function getGame(uint gameId) public view returns (address payable[2] memory playersInGame, uint8[7][6] memory gameBoard, uint8 currentPlayer, address winnerAddress, uint256 totalWager, bool gameActive) {
    Game storage game = games[gameId];
    address payable[2] memory playerAddresses = [game.players[0].playerAddress, game.players[1].playerAddress];
    return (playerAddresses, game.board, game.currentPlayer, game.winner, game.players[0].wager + game.players[0].wager, !game.ended);
  }

  function getPlayerWagers(uint gameId) public view returns (address payable[2] memory playerAddress, uint[2] memory wager, uint8[2] memory playerColor) {
    Game storage game = games[gameId];
    address payable[2] memory playerAddresses = [game.players[0].playerAddress, game.players[1].playerAddress];
    uint[2] memory wagers = [game.players[0].wager, game.players[1].wager];
    uint8[2] memory colors = [game.players[0].playerColor, game.players[1].playerColor];
    return (playerAddresses, wagers, colors);
  }

  function adminDrawGame(uint gameId) public onlyRole(DEFAULT_ADMIN_ROLE) {
    Game storage game = games[gameId];

    if (game.winner == address(0) && !game.ended && game.players[1].wager != 0 && game.totalBet >= game.wager) {
        uint refundAmount = game.players[0].wager;
        game.totalBet -= refundAmount;

        payable(game.players[0].playerAddress).transfer(refundAmount);
        emit WagerWithdrawn(game.players[0].playerAddress, gameId, refundAmount);

        refundAmount = game.players[1].wager;
        game.totalBet -= refundAmount;
        payable(game.players[1].playerAddress).transfer(refundAmount);
        emit WagerWithdrawn(game.players[1].playerAddress, gameId, refundAmount);
    }

    if (game.winner == address(0) && !game.ended && game.players[1].wager == 0 && game.totalBet >= game.wager) {
        uint refundAmount = game.players[0].wager;
        game.totalBet -= refundAmount;

        payable(game.players[0].playerAddress).transfer(refundAmount);
        emit WagerWithdrawn(game.players[0].playerAddress, gameId, refundAmount);
    }

    game.ended = true;
    emit GameEnded(game.players[0].playerAddress, game.players[1].playerAddress, gameId);
  }

  function withdrawFromContract() public onlyRole(DEFAULT_ADMIN_ROLE) {
    payable(msg.sender).transfer(address(this).balance);
  }

  function allActiveGames(address _playerAddress) public view returns (Game[] game){
    Game[] memory activeGames;
    for(uint i = 0; i < games.length; i++){
      if((games[i].players[0].playerAddress == _playerAddress || games[i].players[1].playerAddress == _playerAddress) && games[i].ended == false){
        activeGames[i] = games[i];
      }
    }
    return activeGames;
  }
}
