## CONNECT4-With-Wager

This a connect 4 game with wager. The game is played between two players. Each player has a wager amount. The winner takes the wager amount of the loser. The game is played on a 6x7 board. The players take turns to drop a piece in the board. The first player to get 4 pieces in a row, column or diagonal wins the game. The game ends in a draw if the board is full and no player has won.

All actions are on-chain.

Contract can be deployed on any chain.

### Steps to play the game

1. Start a game, call `startGame` with the wager amount. The wager amount is the amount of tokens that the winner will get from the loser. The wager amount is sent to the contract and locked in the contract until the game ends. The wager amount is sent to the contract by the player who starts the game. The player who starts the game is player 1. The player who joins the game is player 2.
2. Player2 can join the game by calling `joinGame` with the wager amount. The wager amount is the amount of tokens that the winner will get from the loser. The wager amount is sent to the contract and locked in the contract until the game ends. The wager amount is sent to the contract by the player who joins the game. The player who starts the game is player 1. The player who joins the game is player 2.
3. Use he function `makeMove` to make a move. The function takes three arguments

- gameId
- playerAddress
- column
  The column is filled from the bottom. The first row is row 0. The last row is row 5. The first column is column 0. The last column is column 6.

4. On every `makeMove` call, the contract checks if the game is won or drawn. If the game is won, the contract transfers the wager amount to the winner. If the game is drawn, the contract transfers the wager amount to both the players.

### Steps to deploy the contract

1. Clone the repo
2. Goto `contract` folder
3. Run `npm install`
4. Run `npx thirdweb deploy`
5. Follow UI instructions to deploy

### Steps to run the UI

1. Clone the repo
2. Goto `ui` folder
3. Run `yarn`
4. Run `yarn dev`
5. Open `localhost:3000` in the browser

## To do

- [ ] Allow UI to prompt the user and then select the column to put the piece in
- [x] Update contract code to now check for a win or draw after every move. Only do this after both the users have made atleast 4 moves.
